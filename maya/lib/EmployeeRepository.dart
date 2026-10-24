import 'ApiClient.dart';

class AttendanceRecord {
  final String code;
  final String name;
  final DateTime time;
  final bool isCheckIn; // true = quét vào, false = quét ra

  const AttendanceRecord({
    required this.code,
    required this.name,
    required this.time,
    required this.isCheckIn,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) => AttendanceRecord(
    code: j['code'] as String,
    name: j['name'] as String,
    time: DateTime.parse(j['time'] as String).toLocal(),
    isCheckIn: j['isCheckIn'] as bool,
  );
}

/// Kết quả của 1 lượt quét chấm công
class ScanResult {
  final AttendanceRecord record;
  final bool alreadyDone; // true = hôm nay đã quét RA rồi, lượt này không được ghi
  final String status; // nhãn trạng thái do server tính (Đúng giờ / Đi trễ / ...)

  const ScanResult(this.record, {this.alreadyDone = false, this.status = ''});
}

/// Tóm tắt 1 ngày công của 1 nhân viên
class DaySummary {
  final DateTime date;
  final DateTime checkIn;
  final DateTime? checkOut; // null = chưa quét ra

  const DaySummary({
    required this.date,
    required this.checkIn,
    required this.checkOut,
  });

  factory DaySummary.fromJson(Map<String, dynamic> j) => DaySummary(
    date: DateTime.parse(j['date'] as String),
    checkIn: DateTime.parse(j['checkIn'] as String),
    checkOut: j['checkOut'] == null
        ? null
        : DateTime.parse(j['checkOut'] as String),
  );
}

/// Dữ liệu nằm trên backend, class này chỉ gọi API (giữ nguyên tên hàm cũ)
class EmployeeRepository {
  EmployeeRepository._();
  static final EmployeeRepository instance = EmployeeRepository._();

  final _api = ApiClient.instance;

  // ---------------------------------------------------------------- Nhân viên

  Future<int> count() async => (await employees()).length;

  Future<List<MapEntry<String, String>>> employees() async {
    final list = await _api.get('/api/employees') as List;
    return list
        .map((e) => MapEntry<String, String>(e['code'] as String, e['name'] as String))
        .toList();
  }

  Future<Map<String, dynamic>?> _employee(String code) async {
    try {
      return await _api.get('/api/employees/${Uri.encodeComponent(code)}')
      as Map<String, dynamic>;
    } on ApiException catch (e) {
      if (e.status == 404) return null;
      rethrow;
    }
  }

  Future<String?> getName(String code) async =>
      (await _employee(code))?['name'] as String?;

  /// Nhân viên này đã liên kết với 1 điện thoại chưa?
  Future<bool> hasDevice(String code) async =>
      (await _employee(code))?['bound'] as bool? ?? false;

  Future<void> updateName(String code, String newName) =>
      _api.put('/api/employees/${Uri.encodeComponent(code)}', {'name': newName});

  Future<bool> delete(String code) async {
    try {
      await _api.delete('/api/employees/${Uri.encodeComponent(code)}');
      return true;
    } on ApiException catch (e) {
      if (e.status == 404) return false;
      rethrow;
    }
  }

  /// Thêm nhân viên mới. Trả về false nếu mã đã tồn tại.
  Future<bool> addEmployee(String code, String name, {String? password}) async {
    try {
      await _api.post('/api/employees',
          {'code': code, 'name': name, 'password': password ?? ''});
      return true;
    } on ApiException catch (e) {
      if (e.status == 409) return false;
      rethrow;
    }
  }

  // ---------------------------------------------------------------- Mật khẩu / máy nhân viên

  /// Đặt / đặt lại mật khẩu (đồng thời hủy liên kết máy cũ)
  Future<void> setPassword(String code, String password) => _api.post(
      '/api/employees/${Uri.encodeComponent(code)}/password',
      {'password': password});

  /// Hủy liên kết máy: nhân viên phải kích hoạt lại bằng mật khẩu
  Future<void> unbindDevice(String code) =>
      _api.post('/api/employees/${Uri.encodeComponent(code)}/unbind');

  /// Các device_id đang gắn với từ 2 tài khoản trở lên -> danh sách (mã, tên)
  Future<Map<String, List<MapEntry<String, String>>>> duplicateDevices() async {
    final list = await _api.get('/api/devices/duplicates') as List;
    final map = <String, List<MapEntry<String, String>>>{};
    for (final g in list) {
      map[g['deviceId'] as String] = (g['accounts'] as List)
          .map((a) => MapEntry<String, String>(a['code'] as String, a['name'] as String))
          .toList();
    }
    return map;
  }

  // ---------------------------------------------------------------- Chấm công

  /// Lượt quét gần nhất (mới nhất trước)
  Future<List<AttendanceRecord>> history({int limit = 50}) async {
    final list = await _api
        .get('/api/attendance/history', query: {'limit': '$limit'}) as List;
    return list
        .map((j) => AttendanceRecord.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Gửi gói chấm công lên backend. Trả về null nếu token/máy không hợp lệ.
  Future<ScanResult?> checkIn(String code, String token, String deviceId) async {
    try {
      final j = await _api.post('/api/attendance/checkin',
          {'code': code, 'token': token, 'deviceId': deviceId}) as Map<String, dynamic>;
      return ScanResult(
        AttendanceRecord.fromJson(j),
        alreadyDone: j['alreadyDone'] as bool,
        status: j['status'] as String,
      );
    } on ApiException catch (e) {
      if (e.status == 401) return null;
      rethrow;
    }
  }

  /// Chi tiết chấm công của 1 nhân viên trong 1 tháng (theo từng ngày).
  Future<List<DaySummary>> monthSummary(String code, int year, int month) async {
    final list = await _api.get('/api/reports/monthly', query: {
      'code': code,
      'year': '$year',
      'month': '$month',
    }) as List;
    return list
        .map((j) => DaySummary.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ---------------------------------------------------------------- Giờ làm

  /// {"checkInMinutes": int, "checkOutMinutes": int}
  Future<Map<String, dynamic>> getSchedule() async =>
      await _api.get('/api/settings/schedule') as Map<String, dynamic>;

  Future<void> setSchedule(int checkInMinutes, int checkOutMinutes) =>
      _api.put('/api/settings/schedule', {
        'checkInMinutes': checkInMinutes,
        'checkOutMinutes': checkOutMinutes,
      });
}