import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

final RegExp _qrCodeRule = RegExp(r'^\d{10,12}$');

/// Trang quét QR dùng chung: trả về mã nhân viên (10–12 chữ số), mã sai thì bỏ qua và quét tiếp
class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quét mã QR nhân viên")),
      body: MobileScanner(
        onDetect: (capture) {
          if (_done) return;
          for (final b in capture.barcodes) {
            final v = b.rawValue?.trim();
            if (v != null && _qrCodeRule.hasMatch(v)) {
              _done = true;
              Navigator.pop(context, v);
              return;
            }
          }
        },
      ),
    );
  }
}