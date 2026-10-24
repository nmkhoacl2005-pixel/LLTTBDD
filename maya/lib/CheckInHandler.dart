import 'dart:async';
import 'dart:convert';

import 'ApiClient.dart';
import 'EmployeeRepository.dart';

/// Nhận gói chấm công từ điện thoại nhân viên qua BLE, chuyển lên backend xử lý
/// rồi trả chuỗi JSON để gửi lại cho điện thoại.
///
/// Gói chấm công: {"t":"C","c":"<mã>","k":"<token>","d":"<ID máy>"}
///   -> {"ok":1,"in":1|0,"done":1|0,"s":"<trạng thái>","n":"<tên>","tm":<ms>}
/// Lỗi: {"ok":0,"e":"<lý do>"}
/// (Kích hoạt và báo cáo tháng: điện thoại nhân viên gọi API trực tiếp)
class CheckInHandler {
  CheckInHandler._();
  static final CheckInHandler instance = CheckInHandler._();

  final _repo = EmployeeRepository.instance;
  final _results = StreamController<ScanResult>.broadcast();

  /// Mỗi lượt chấm công thành công -> màn hình Chấm công lắng nghe luồng này
  Stream<ScanResult> get results => _results.stream;

  String _err(String e) => jsonEncode({'ok': 0, 'e': e});

  Future<String> handle(String raw) async {
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final code = (m['c'] ?? '').toString();
      final device = (m['d'] ?? '').toString();
      if (code.isEmpty || device.isEmpty) return _err('Gói không hợp lệ');

      if (m['t'] == 'C') {
        return await _checkIn(code, (m['k'] ?? '').toString(), device);
      }
      return _err('Gói không hợp lệ');
    } on ApiException catch (e) {
      return _err(e.status == null ? 'Máy trạm mất kết nối server' : e.message);
    } catch (_) {
      return _err('Gói không hợp lệ');
    }
  }

  Future<String> _checkIn(String code, String token, String device) async {
    final res = await _repo.checkIn(code, token, device);
    if (res == null) return _err('Máy chưa được liên kết');

    _results.add(res);

    final r = res.record;
    return jsonEncode({
      'ok': 1,
      'in': r.isCheckIn ? 1 : 0,
      'done': res.alreadyDone ? 1 : 0,
      's': res.status,
      'n': r.name,
      'tm': r.time.millisecondsSinceEpoch,
    });
  }
}