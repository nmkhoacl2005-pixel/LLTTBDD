import 'package:flutter/material.dart';
import 'AddEmployeeScreen.dart';
import 'AttendanceScreen.dart';
import 'BluetoothService.dart';
import 'DeleteEmployeeScreen.dart';
import 'EditEmployeeScreen.dart';
import 'MonthlyReportScreen.dart';
import 'ScheduleSettingsScreen.dart';
import 'DuplicateDeviceScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Chỉ màn hình đang chọn được build
  final List<Widget> _widgetOptions = const <Widget>[
    AttendanceScreen(), // giao diện chấm công (tên + giờ)
    AddEmployeeScreen(), // giao diện thêm nhân viên mới
    EditEmployeeScreen(), // giao diện sửa nhân viên
    DeleteEmployeeScreen(), // giao diện xóa nhân viên
    MonthlyReportScreen(), // giao diện chi tiết chấm công theo tháng
    ScheduleSettingsScreen(), // giao diện cài đặt giờ làm
    DuplicateDeviceScreen(),
  ];

  final List<String> _titles = const [
    'Chấm công',
    'Thêm nhân viên',
    'Sửa nhân viên',
    'Xóa nhân viên',
    'Báo cáo tháng',
    'Giờ làm việc',
    'Cảnh báo trùng máy',
  ];

  void _onItemTapped(int index) {
    // hàm chuyển đổi giữa các tab
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    BluetoothService.instance.stop();
    super.dispose();
  }

  /// Nút Mở / Đóng máy trạm trên thanh tiêu đề
  Widget _stationButton() {
    final bt = BluetoothService.instance;
    return ValueListenableBuilder<bool>(
      valueListenable: bt.running,
      builder: (context, running, _) => TextButton.icon(
        onPressed: () => running ? bt.stop() : bt.start(),
        icon: Icon(
          running ? Icons.stop_circle_outlined : Icons.play_circle_outline,
          color: Colors.white,
          size: 20,
        ),
        label: Text(
          running ? "Đóng máy trạm" : "Mở máy trạm",
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [_stationButton()],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Chấm công',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: 'Thêm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: 'Sửa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.delete),
            label: 'Xóa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Báo cáo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Giờ làm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning_amber_rounded),
            label: 'Trùng máy',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: _onItemTapped,
      ),
    );
  }
}