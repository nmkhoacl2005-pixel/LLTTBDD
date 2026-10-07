import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';

/// Chạy Bluetooth Server 1 lần duy nhất cho cả app.
/// Mỗi màn hình chỉ cần lắng nghe [scans] để nhận mã QR từ Máy B.
class BluetoothService {
  BluetoothService._();
  static final BluetoothService instance = BluetoothService._();

  final _bluetooth = FlutterClassicBluetooth();
  dynamic _server;
  bool _started = false;

  final ValueNotifier<String> status =
      ValueNotifier<String>("Đang khởi tạo Server...");
  final ValueNotifier<bool> connected = ValueNotifier<bool>(false);

  final StreamController<String> _scanController =
      StreamController<String>.broadcast();

  /// Luồng mã QR nhận từ Máy B
  Stream<String> get scans => _scanController.stream;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    try {
      // 1. Kiểm tra thiết bị có hỗ trợ làm Server Bluetooth không
      final caps = await _bluetooth.getPlatformCapabilities();
      if (!caps.canCreateServer) {
        status.value = "Thiết bị này không hỗ trợ làm Server Bluetooth!";
        return;
      }

      // 2. Mở Server lắng nghe kết nối
      _server = await _bluetooth.startServer(
        serviceName: "May_Cham_Cong",
        uuid: BtcUuid.spp,
      );
      status.value = "Đang chờ Máy B kết nối...";

      // 3. Khi Máy B kết nối vào
      _server!.connections.listen((BtcConnection connection) {
        connected.value = true;
        status.value = "Máy B đã kết nối";

        // 4. Nhận mã QR và phát cho các màn hình
        connection.input.lines().listen(
          (String qrCode) {
            final code = qrCode.trim();
            if (code.isNotEmpty) _scanController.add(code);
          },
          onDone: () {
            connected.value = false;
            status.value = "Máy B đã ngắt kết nối. Đang chờ lại...";
          },
          onError: (error) {
            debugPrint("Lỗi nhận dữ liệu: $error");
          },
        );
      });
    } catch (e) {
      _started = false;
      status.value = "Lỗi khởi tạo Server: $e";
    }
  }

  void stop() {
    _server?.dispose();
    _server = null;
    _started = false;
    connected.value = false;
  }
}
