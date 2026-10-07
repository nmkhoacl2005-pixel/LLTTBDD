import 'package:flutter/material.dart';
import 'AddEmployeeScreen.dart';
import 'AttendanceScreen.dart';
import 'BluetoothService.dart';
import 'DeleteEmployeeScreen.dart';
import 'EditEmployeeScreen.dart';
import 'MonthlyReportScreen.dart';
import 'ScheduleSettingsScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Chỉ màn hình đang chọn được build -> chỉ màn đó nhận mã QR từ Máy B
  final List<Widget> _widgetOptions = const <Widget>[
    AttendanceScreen(), // giao diện chấm công (tên + giờ)
    AddEmployeeScreen(), // giao diện thêm nhân viên mới
    EditEmployeeScreen(), // giao diện sửa nhân viên
    DeleteEmployeeScreen(), // giao diện xóa nhân viên
    MonthlyReportScreen(), // giao diện chi tiết chấm công theo tháng
    ScheduleSettingsScreen(), // giao diện cài đặt giờ làm
  ];

  final List<String> _titles = const [
    'Chấm công',
    'Thêm nhân viên',
    'Sửa nhân viên',
    'Xóa nhân viên',
    'Báo cáo tháng',
    'Giờ làm việc',
  ];

  @override
  void initState() {
    super.initState();
    BluetoothService.instance.start(); // mở Bluetooth Server 1 lần
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
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