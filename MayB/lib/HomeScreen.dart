import 'package:flutter/material.dart';
import 'CheckInScreen.dart';
import 'EmpWidgets.dart';
import 'ReportScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = const <Widget>[
    CheckInScreen(), // nút chấm công
    ReportScreen(), // báo cáo tháng của mình
  ];

  final List<String> _titles = const ['Chấm công', 'Báo cáo tháng'];

  Future<void> _logout() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.logout, color: Colors.deepOrange, size: 44),
        title: const Text('Đăng xuất'),
        content: const Text(
          'Bạn sẽ phải kích hoạt lại bằng mã và mật khẩu.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đồng ý')),
        ],
      ),
    );
    if (yes == true && mounted) goActivate(context, null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _logout,
          ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: 'Chấm công'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Báo cáo'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}
