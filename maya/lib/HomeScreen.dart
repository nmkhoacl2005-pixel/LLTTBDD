import 'package:flutter/material.dart';
import 'AddEmployeeScreen.dart';
import 'AttendanceScreen.dart';
import 'DashboardScreen.dart';
import 'BluetoothService.dart';
import 'DeleteEmployeeScreen.dart';
import 'EditEmployeeScreen.dart';
import 'MonthlyReportScreen.dart';
import 'ScheduleSettingsScreen.dart';
import 'DuplicateDeviceScreen.dart';
import 'HolidayScreen.dart';
import 'LeaveApprovalScreen.dart';
import 'PayrollScreen.dart';
import 'AnnouncementScreen.dart';

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
    HolidayScreen(), // quản lý ngày lễ
    LeaveApprovalScreen(), // duyệt đơn xin nghỉ
    PayrollScreen(), // bảng lương tháng
    AnnouncementScreen(), // viết thông báo cho nhân viên
  ];
  final List<String> _titles = const [
    'Tổng quan',
    'Chấm công',
    'Thêm nhân viên',
    'Sửa nhân viên',
    'Xóa nhân viên',
    'Báo cáo tháng',
    'Giờ làm việc',
    'Cảnh báo trùng máy',
    'Ngày lễ',
    'Duyệt đơn nghỉ',
    'Bảng lương',
    'Thông báo',
  ];

  final List<IconData> _icons = const [
    Icons.dashboard,
    Icons.access_time,
    Icons.person_add,
    Icons.edit,
    Icons.delete,
    Icons.calendar_month,
    Icons.schedule,
    Icons.warning_amber_rounded,
    Icons.celebration,
    Icons.event_busy,
    Icons.payments,
    Icons.campaign,
  ];

  /// Tab 0 = Tổng quan (cần callback nên không nằm trong _widgetOptions const),
  /// các tab còn lại lấy từ _widgetOptions với chỉ số lùi 1
  Widget _body() {
    if (_selectedIndex == 0) return DashboardScreen(onNavigate: _onItemTapped);
    return _widgetOptions.elementAt(_selectedIndex - 1);
  }

  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const ListTile(
              title: Text(
                'Quản lý chấm công',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            for (var i = 0; i < _titles.length; i++)
              ListTile(
                leading: Icon(_icons[i]),
                title: Text(_titles[i]),
                selected: i == _selectedIndex,
                selectedColor: Colors.indigo,
                onTap: () {
                  Navigator.pop(context);
                  _onItemTapped(i);
                },
              ),
          ],
        ),
      ),
    );
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
drawer: _buildDrawer(),
      body: _body(),
bottomNavigationBar: null,
/* bottomNavigationBar: BottomNavigationBar(
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
      ), */
    );
  }
}