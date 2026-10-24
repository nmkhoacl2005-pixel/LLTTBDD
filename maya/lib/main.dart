import 'package:flutter/material.dart';
import 'EmployeeRepository.dart';
import 'HomeScreen.dart';
import 'WorkSchedule.dart';
import 'ApiClient.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final messengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Không đọc được .env: $e");
  }
  // Lỗi API chưa được bắt ở màn hình nào thì hiện snackbar
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    if (error is ApiException) {
      messengerKey.currentState?.showSnackBar(SnackBar(
        content: Text(error.message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
      return true;
    }
    return false;
  };
  await WorkSchedule.instance.load(); // nạp giờ làm từ server
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: messengerKey,
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