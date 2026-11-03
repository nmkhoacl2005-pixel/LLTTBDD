import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mayb/HomeScreen.dart';
import 'ActivateScreen.dart';
import 'AuthStorage.dart';
import 'PushService.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // Try-catch để nếu thiếu google-services.json app vẫn không bị đen thui
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Lỗi Firebase: $e');
  }

  final activated = await AuthStorage.isActivated();

  // Phải cho app vẽ giao diện lên trước
  runApp(MyApp(activated: activated));

  // Xin quyền và lấy token CHẠY NGẦM sau khi app đã lên hình
  if (activated) {
    PushService.instance.init().catchError((e) => debugPrint('Lỗi Push: $e'));
  }
}

class MyApp extends StatelessWidget {
  final bool activated;
  const MyApp({Key? key, required this.activated}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chấm công nhân viên',
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
      home: activated ? const HomeScreen() : const ActivateScreen(),
    );
  }
}