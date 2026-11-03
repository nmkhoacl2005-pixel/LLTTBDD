import 'package:flutter/foundation.dart'; // Thêm thư viện này để in log
import 'package:firebase_messaging/firebase_messaging.dart';
import 'BleClient.dart';

/// Nhận thông báo đẩy (FCM) và gửi token của máy lên server
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  /// Màn hình chính gán hàm này để hiện thông báo khi app đang mở
  /// (lúc app đang mở FCM không tự hiện thông báo)
  void Function(String title, String body)? onForeground;
  bool _started = false;

  /// Gọi 1 lần sau Firebase.initializeApp() và mỗi khi kích hoạt lại
  Future<void> init() async {
    if (!_started) {
      _started = true;
      await FirebaseMessaging.instance.requestPermission();
      FirebaseMessaging.instance.onTokenRefresh.listen(_upload);
      FirebaseMessaging.onMessage.listen((m) {
        final n = m.notification;
        if (n != null) onForeground?.call(n.title ?? '', n.body ?? '');
      });
    }

    // Đưa lệnh này ra ngoài khối if, để tài khoản mới đăng nhập
    // luôn bắt buộc phải báo danh (gửi token) lên server lại
    await syncToken();
  }

  /// Gọi lại sau khi kích hoạt máy thành công
  Future<void> syncToken() async {
    try {
      final t = await FirebaseMessaging.instance.getToken();
      debugPrint('==== FCM TOKEN LẤY TỪ GOOGLE: $t ===='); // IN LOG XEM CÓ TOKEN KHÔNG

      if (t != null) {
        final r = await BleClient.instance.saveFcmToken(t);
        debugPrint('==== KẾT QUẢ GỬI LÊN BACKEND: ok=${r.ok}, lỗi=${r.error} ===='); // IN LOG GỬI API
      }
    } catch (e) {
      debugPrint('==== LỖI LẤY TOKEN TỪ GOOGLE: $e ===='); // IN LỖI NẾU CÓ
    }
  }

  Future<void> _upload(String t) => BleClient.instance.saveFcmToken(t);
}