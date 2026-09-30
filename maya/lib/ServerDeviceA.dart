import 'package:flutter/material.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';

class ServerDeviceA extends StatefulWidget {
  const ServerDeviceA({Key? key}) : super(key: key);

  @override
  _ServerDeviceAState createState() => _ServerDeviceAState();
}

class _ServerDeviceAState extends State<ServerDeviceA> {
  final _bluetooth = FlutterClassicBluetooth();
  dynamic _server;

  // Trạng thái hiển thị trên màn hình
  String _serverStatus = "Đang khởi tạo Server...";
  String _scanResult = "Chưa có dữ liệu";
  Color _resultColor = Colors.grey;

  // Cơ sở dữ liệu giả lập (Mock Database)
  final Map<String, String> _employeeDb = {
    "2380601068": "Nguyễn Minh Khoa",
    "2380602431": "Nguyễn Phạm Tuân",
    "2380600564": "Đặng Thị Thái Hà",
    "2380600226": "Triệu Thị Mai Chi",
  };

  @override
  void initState() {
    super.initState();
    _startServer();
  }

  Future<void> _startServer() async {
    try {
      // 1. Kiểm tra xem điện thoại có hỗ trợ làm Server Bluetooth không
      final caps = await _bluetooth.getPlatformCapabilities();
      if (!caps.canCreateServer) {
        setState(() => _serverStatus = "Thiết bị này không hỗ trợ làm Server Bluetooth!");
        return;
      }

      // 2. Mở Server lắng nghe kết nối
      _server = await _bluetooth.startServer(
        serviceName: "May_Cham_Cong",
        uuid: BtcUuid.spp,
      );

      setState(() => _serverStatus = "Đang chờ Máy B kết nối...");

      // 3. Lắng nghe khi có thiết bị (Máy B) kết nối vào
      _server!.connections.listen((BtcConnection connection) {
        if (mounted) {
          setState(() {
            _serverStatus = "✅ Máy B đã kết nối!";
            _scanResult = "Sẵn sàng quét mã...";
            _resultColor = Colors.blue;
          });
        }

        // 4. Lắng nghe dữ liệu (mã QR) do Máy B gửi tới
        connection.input.lines().listen(
              (String qrCode) {
            _handleQRCode(qrCode.trim());
          },
          onDone: () {
            // Khi Máy B ngắt kết nối
            if (mounted) {
              setState(() {
                _serverStatus = "❌ Máy B đã ngắt kết nối. Đang chờ lại...";
                _scanResult = "Chưa có dữ liệu";
                _resultColor = Colors.grey;
              });
            }
          },
          onError: (error) {
            print("Lỗi nhận dữ liệu: $error");
          },
        );
      });
    } catch (e) {
      setState(() => _serverStatus = "Lỗi khởi tạo Server: $e");
    }
  }

  // Hàm xử lý mã QR nhận được
  void _handleQRCode(String qrCode) {
    setState(() {
      if (_employeeDb.containsKey(qrCode)) {
        // Hợp lệ
        _scanResult = "Chấm công thành công!\nXin chào: ${_employeeDb[qrCode]}";
        _resultColor = Colors.green;
      } else {
        // Không hợp lệ
        _scanResult = "Mã QR không hợp lệ!\n($qrCode)";
        _resultColor = Colors.red;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Máy Chủ (Máy A)"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hiển thị trạng thái máy chủ
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _serverStatus,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 60),

            // Hiển thị kết quả quét QR
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: _resultColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                child: Text(
                  _scanResult,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _resultColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _server?.dispose(); // Đóng server khi tắt màn hình này
    super.dispose();
  }
}