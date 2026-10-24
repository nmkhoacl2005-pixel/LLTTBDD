import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'Protocol.dart';

class AuthStorage {
  static const _s = FlutterSecureStorage();
  static const _kCode = 'emp_code';
  static const _kToken = 'emp_token';
  static const _kName = 'emp_name';
  static const _kDevice = 'device_id';

  static Future<String?> code() => _s.read(key: _kCode);
  static Future<String?> token() => _s.read(key: _kToken);
  static Future<String?> name() => _s.read(key: _kName);

  static Future<bool> isActivated() async => (await token()) != null;

  /// ID máy: ưu tiên UDID thật, dự phòng là ID tự sinh (lưu cố định)
  static Future<String> deviceId() async {
    try {
      final u = await FlutterUdid.consistentUdid;
      if (u.isNotEmpty) return u;
    } catch (_) {}
    var id = await _s.read(key: _kDevice);
    if (id == null || id.isEmpty) {
      final r = Random.secure();
      id = List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      await _s.write(key: _kDevice, value: id);
    }
    return id;
  }

  static Future<void> save(String code, String token, String name) async {
    await _s.write(key: _kCode, value: code);
    await _s.write(key: _kToken, value: token);
    await _s.write(key: _kName, value: name);
  }

  /// Xóa thông tin đăng nhập (giữ ID máy) và cache báo cáo
  static Future<void> clear() async {
    reportCache.clear();
    await _s.delete(key: _kCode);
    await _s.delete(key: _kToken);
    await _s.delete(key: _kName);
  }
}