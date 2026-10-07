import 'package:flutter/material.dart';
import 'EmployeeRepository.dart';
import 'HomeScreen.dart';
import 'WorkSchedule.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EmployeeRepository.instance.init(); // mở SQLite
  await WorkSchedule.instance.load(); // nạp giờ làm đã lưu
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomeScreen(), // vào thẳng HomeScreen có 3 tab
    );
  }
}