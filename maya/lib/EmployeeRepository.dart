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
  final DateTime? checkIn; // null = ngày không quét (nghỉ / lễ / vắng)
  final DateTime? checkOut; // null = chưa quét ra
  final String kind; // Work | Leave | Holiday | Absent
  final String label;

  const DaySummary({
    required this.date,
    required this.checkIn,
    required this.checkOut,
    this.kind = 'Work',
    this.label = '',
  });

  bool get isWork => kind == 'Work';

  factory DaySummary.fromJson(Map<String, dynamic> j) => DaySummary(
    date: DateTime.parse(j['date'] as String),
    checkIn: j['checkIn'] == null
        ? null
        : DateTime.parse(j['checkIn'] as String),
    checkOut: j['checkOut'] == null
        ? null
        : DateTime.parse(j['checkOut'] as String),
    kind: (j['kind'] as String?) ?? 'Work',
    label: (j['label'] as String?) ?? '',
  );
}

String _ymd(DateTime d) =>
    "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

class Holiday {
  final int id;
  final DateTime date;
  final String name;

  const Holiday({required this.id, required this.date, required this.name});

  factory Holiday.fromJson(Map<String, dynamic> j) => Holiday(
    id: j['id'] as int,
    date: DateTime.parse(j['date'] as String),
    name: j['name'] as String,
  );
}

class LeaveRequest {
  final int id;
  final String code;
  final String name;
  final DateTime fromDate;
  final DateTime toDate;
  final String type;
  final String reason;
  final String status; // Pending | Approved | Rejected

  const LeaveRequest({
    required this.id,
    required this.code,
    required this.name,
    required this.fromDate,
    required this.toDate,
    required this.type,
    required this.reason,
    required this.status,
  });

  int get days => toDate.difference(fromDate).inDays + 1;

  factory LeaveRequest.fromJson(Map<String, dynamic> j) => LeaveRequest(
    id: j['id'] as int,
    code: j['code'] as String,
    name: j['name'] as String,
    fromDate: DateTime.parse(j['fromDate'] as String),
    toDate: DateTime.parse(j['toDate'] as String),
    type: j['type'] as String,
    reason: j['reason'] as String,
    status: j['status'] as String,
  );
}

class PayrollRow {
  final String code;
  final String name;
  final double hourlyRate;
  final int workDays;
  final int absentDays;
  final int paidLeaveDays;
  final int unpaidLeaveDays;
  final int missingCheckOut;
  final int annualLeaveUsed;
  final int annualLeaveQuota;
  final double regularHours;
  final double otHours;
  final double weekendHours;
  final double holidayWorkedHours;
  final double holidayPaidHours;
  final double paidLeaveHours;
  final double gross;

  const PayrollRow({
    required this.code,
    required this.name,
    required this.hourlyRate,
    required this.workDays,
    required this.absentDays,
    required this.paidLeaveDays,
    required this.unpaidLeaveDays,
    required this.missingCheckOut,
    required this.annualLeaveUsed,
    required this.annualLeaveQuota,
    required this.regularHours,
    required this.otHours,
    required this.weekendHours,
    required this.holidayWorkedHours,
    required this.holidayPaidHours,
    required this.paidLeaveHours,
    required this.gross,
  });

  factory PayrollRow.fromJson(Map<String, dynamic> j) => PayrollRow(
    code: j['code'] as String,
    name: j['name'] as String,
    hourlyRate: (j['hourlyRate'] as num).toDouble(),
    workDays: (j['workDays'] as num).toInt(),
    absentDays: (j['absentDays'] as num).toInt(),
    paidLeaveDays: (j['paidLeaveDays'] as num).toInt(),
    unpaidLeaveDays: (j['unpaidLeaveDays'] as num).toInt(),
    missingCheckOut: (j['missingCheckOut'] as num).toInt(),
    annualLeaveUsed: (j['annualLeaveUsed'] as num).toInt(),
    annualLeaveQuota: (j['annualLeaveQuota'] as num).toInt(),
    regularHours: (j['regularHours'] as num).toDouble(),
    otHours: (j['otHours'] as num).toDouble(),
    weekendHours: (j['weekendHours'] as num).toDouble(),
    holidayWorkedHours: (j['holidayWorkedHours'] as num).toDouble(),
    holidayPaidHours: (j['holidayPaidHours'] as num).toDouble(),
    paidLeaveHours: (j['paidLeaveHours'] as num).toDouble(),
    gross: (j['gross'] as num).toDouble(),
  );
}

class DashboardRow {
  final String code;
  final String name;
  final String status; // Working | Done | Leave | NotYet
  final String label;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final bool isLate;

  const DashboardRow({
    required this.code,
    required this.name,
    required this.status,
    required this.label,
    required this.checkIn,
    required this.checkOut,
    required this.isLate,
  });

  factory DashboardRow.fromJson(Map<String, dynamic> j) => DashboardRow(
    code: j['code'] as String,
    name: j['name'] as String,
    status: j['status'] as String,
    label: (j['label'] as String?) ?? '',
    checkIn: j['checkIn'] == null ? null : DateTime.parse(j['checkIn'] as String),
    checkOut: j['checkOut'] == null ? null : DateTime.parse(j['checkOut'] as String),
    isLate: j['isLate'] as bool,
  );
}

class DashboardData {
  final DateTime date;
  final String? holidayName;
  final int totalEmployees;
  final int pendingLeaves;
  final int duplicateDevices;
  final int missedCheckOutYesterday;
  final List<DashboardRow> rows;

  const DashboardData({
    required this.date,
    required this.holidayName,
    required this.totalEmployees,
    required this.pendingLeaves,
    required this.duplicateDevices,
    required this.missedCheckOutYesterday,
    required this.rows,
  });

  factory DashboardData.fromJson(Map<String, dynamic> j) => DashboardData(
    date: DateTime.parse(j['date'] as String),
    holidayName: j['holidayName'] as String?,
    totalEmployees: (j['totalEmployees'] as num).toInt(),
    pendingLeaves: (j['pendingLeaves'] as num).toInt(),
    duplicateDevices: (j['duplicateDevices'] as num).toInt(),
    missedCheckOutYesterday: (j['missedCheckOutYesterday'] as num).toInt(),
    rows: (j['rows'] as List)
        .map((r) => DashboardRow.fromJson(r as Map<String, dynamic>))
        .toList(),
  );
}

class AnnouncementItem {
  final int id;
  final String title;
  final String body;
  final DateTime createdAt;

  const AnnouncementItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  factory AnnouncementItem.fromJson(Map<String, dynamic> j) => AnnouncementItem(
    id: j['id'] as int,
    title: j['title'] as String,
    body: j['body'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
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

  // ---------------------------------------------------------------- Ngày lễ

  Future<List<Holiday>> holidays({int? year}) async {
    final list = await _api.get('/api/holidays',
        query: year == null ? null : {'year': '$year'}) as List;
    return list.map((j) => Holiday.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// false = ngày này đã có
  Future<bool> addHoliday(DateTime date, String name) async {
    try {
      await _api.post('/api/holidays', {'date': _ymd(date), 'name': name});
      return true;
    } on ApiException catch (e) {
      if (e.status == 409) return false;
      rethrow;
    }
  }

  Future<void> deleteHoliday(int id) => _api.delete('/api/holidays/$id');

  // ---------------------------------------------------------------- Đơn nghỉ

  /// status: Pending | Approved | Rejected (null = tất cả)
  Future<List<LeaveRequest>> leaves({String? status}) async {
    final list = await _api.get('/api/leaves',
        query: status == null ? null : {'status': status}) as List;
    return list
        .map((j) => LeaveRequest.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> approveLeave(int id) => _api.post('/api/leaves/$id/approve');

  // ---------------------------------------------------------------- Lương

  Future<double> getHourlyRate(String code) async =>
      ((await _employee(code))?['hourlyRate'] as num?)?.toDouble() ?? 0;

  Future<void> setHourlyRate(String code, double rate) => _api.put(
      '/api/employees/${Uri.encodeComponent(code)}/rate', {'hourlyRate': rate});

  Future<List<PayrollRow>> payroll(int year, int month) async {
    final list = await _api.get('/api/payroll',
        query: {'year': '$year', 'month': '$month'}) as List;
    return list
        .map((j) => PayrollRow.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ---------------------------------------------------------------- Dashboard

  Future<DashboardData> dashboardToday() async => DashboardData.fromJson(
      await _api.get('/api/dashboard/today') as Map<String, dynamic>);

  Future<void> rejectLeave(int id) => _api.post('/api/leaves/$id/reject');

  // ---------------------------------------------------------------- Thông báo

  Future<List<AnnouncementItem>> announcements() async {
    final list = await _api.get('/api/announcements') as List;
    return list
        .map((j) => AnnouncementItem.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> addAnnouncement(String title, String body) =>
      _api.post('/api/announcements', {'title': title, 'body': body});

  Future<void> deleteAnnouncement(int id) => _api.delete('/api/announcements/$id');
}