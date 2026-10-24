import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mayb/HomeScreen.dart';
import 'ActivateScreen.dart';
import 'AuthStorage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  final activated = await AuthStorage.isActivated();
  runApp(MyApp(activated: activated));
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