import 'package:flutter/material.dart';

import 'ServerDeviceA.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ServerDeviceA(), // Chạy thẳng vào màn hình quét QR
      debugShowCheckedModeBanner: false,
    );
  }
}