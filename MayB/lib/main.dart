import 'package:flutter/material.dart';
import 'package:flutter_classic_bluetooth/flutter_classic_bluetooth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ScannerDeviceB.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Máy Quét (Máy B)',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const DeviceSelectionScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DeviceSelectionScreen extends StatefulWidget {
  const DeviceSelectionScreen({Key? key}) : super(key: key);

  @override
  State<DeviceSelectionScreen> createState() => _DeviceSelectionScreenState();
}

class _DeviceSelectionScreenState extends State<DeviceSelectionScreen> {
  final _bluetooth = FlutterClassicBluetooth();
  List<BtcDevice> _devices = [];
  bool _isScanning = false;

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

    try {
      final paired = await _bluetooth.getPairedDevices();
      if (mounted) setState(() => _devices = paired.toList());
    } catch (e) {
      print("Lỗi lấy thiết bị đã ghép nối: $e");
    }

    _startScanning();
  }

  void _startScanning() async {
    if (_isScanning) return;
    setState(() => _isScanning = true);
    try {
      final found = await _bluetooth.scan(timeout: const Duration(seconds: 8));
      if (!mounted) return;
      setState(() {
        for (var d in found) {
          if (!_devices.any((e) => e.address == d.address)) _devices.add(d);
        }
        _isScanning = false;
      });
    } catch (e) {
      print("Lỗi khi quét: $e");
      if (mounted) setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chọn Máy A để kết nối"),
        actions: [
          IconButton(
            icon: _isScanning
                ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.refresh),
            onPressed: _startScanning,
          ),
        ],
      ),
      body: _devices.isEmpty
          ? const Center(child: Text("Đang dò tìm thiết bị xung quanh..."))
          : ListView.builder(
        itemCount: _devices.length,
        itemBuilder: (context, index) {
          final device = _devices[index];
          return ListTile(
            leading: const Icon(Icons.bluetooth, color: Colors.blue),
            title: Text(device.name ?? "Thiết bị không tên",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(device.address),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ScannerDeviceB(
                    serverMacAddress: device.address,
                    serverName: device.name ?? "Máy A",
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}