import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
import 'package:permission_handler/permission_handler.dart';

class ScannerDeviceB extends StatefulWidget {
  final String serverMacAddress;
  final String serverName;

  const ScannerDeviceB({Key? key, required this.serverMacAddress, required this.serverName}) : super(key: key);

  @override
  _ScannerDeviceBState createState() => _ScannerDeviceBState();
}

class _ScannerDeviceBState extends State<ScannerDeviceB> {
  final flutterClassicBluetooth = FlutterClassicBluetooth();
  BtcConnection? _connection;
  bool _isConnected = false;
  bool _connectFailed = false;
  final MobileScannerController _cameraController = MobileScannerController();

  String? _lastScannedCode;
  DateTime? _lastScanTime;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await [
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
      Permission.camera,
    ].request();
    _connectToServer();
  }

  void _connectToServer() async {
    setState(() => _connectFailed = false);
    try {
      final conn = await flutterClassicBluetooth.connect(
        address: widget.serverMacAddress,
        uuid: BtcUuid.spp,
        timeout: const Duration(seconds: 10),
      );
      if (!mounted) return;
      _connection = conn;
      setState(() => _isConnected = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã kết nối với ${widget.serverName}!'), backgroundColor: Colors.green),
      );

      _connection!.input.listen(
            (data) {},
        onDone: () {
          if (mounted) setState(() => _isConnected = false);
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _connectFailed = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _sendData(String qrData) async {
    if (_isConnected && _connection != null) {
      try {
        await _connection!.output.writeLine(qrData);
      } catch (e) {
        print('Lỗi khi gửi: $e');
      }
    }
  }

  void _handleQRCodeDetected(BarcodeCapture capture) {
    if (!mounted) return;
    for (final barcode in capture.barcodes) {
      final String? rawValue = barcode.rawValue;
      if (rawValue != null) {
        final now = DateTime.now();
        bool isSpam = (_lastScannedCode == rawValue) &&
            (_lastScanTime != null) &&
            (now.difference(_lastScanTime!).inSeconds < 2);

        if (!isSpam) {
          _lastScannedCode = rawValue;
          _lastScanTime = now;
          _sendData(rawValue);

          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã gửi: $rawValue'), duration: const Duration(seconds: 1)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isConnected ? "Đang kết nối: ${widget.serverName}" : "Mất kết nối!"),
        backgroundColor: _isConnected ? Colors.green : Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _cameraController,
            onDetect: _handleQRCodeDetected,
          ),
          if (!_isConnected)
            Container(
              color: Colors.black54,
              child: Center(
                child: _connectFailed
                    ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Kết nối thất bại', style: TextStyle(color: Colors.white, fontSize: 18)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _connectToServer, child: const Text('Thử lại')),
                  ],
                )
                    : const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Đang kết nối Bluetooth...', style: TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _connection?.dispose();
    super.dispose();
  }
}