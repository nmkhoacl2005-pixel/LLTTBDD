import 'dart:async';

import 'package:flutter/material.dart';
import 'ApiClient.dart';
import 'CheckInHandler.dart';
import 'CommonWidgets.dart';
import 'EmployeeRepository.dart';

/// Màn đầu tiên: tình hình chấm công hôm nay. Tự làm mới mỗi khi có lượt chấm công mới
class DashboardScreen extends StatefulWidget {
  /// Chuyển sang tab khác của HomeScreen (chỉ số trong Drawer)
  final ValueChanged<int> onNavigate;

  const DashboardScreen({super.key, required this.onNavigate});

  // Phải khớp thứ tự trong _titles của HomeScreen
  static const int duplicateTab = 7;
  static const int leaveTab = 9;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repo = EmployeeRepository.instance;
  StreamSubscription<ScanResult>? _sub;

  DashboardData? _data;
  bool _loading = true;
  String? _error;
  String _filter = 'All'; // All | In | Late | Working | Done | Leave | NotYet

  static const _weekdays = [
    'Thứ hai', 'Thứ ba', 'Thứ tư', 'Thứ năm', 'Thứ sáu', 'Thứ bảy', 'Chủ nhật'
  ];

  @override
  void initState() {
    super.initState();
    _sub = CheckInHandler.instance.results.listen((_) => _load(silent: true));
    _load();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final d = await _repo.dashboardToday();
      if (!mounted) return;
      setState(() {
        _data = d;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (!silent) _error = e.message;
      });
    }
  }

  bool _match(DashboardRow r) {
    switch (_filter) {
      case 'In':
        return r.status == 'Working' || r.status == 'Done';
      case 'Late':
        return r.isLate;
      case 'Working':
      case 'Done':
      case 'Leave':
      case 'NotYet':
        return r.status == _filter;
      default:
        return true;
    }
  }

  Widget _statBox(String label, String value, MaterialColor color, String filter) {
    final selected = _filter == filter;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _filter = selected ? 'All' : filter),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(selected ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color.shade600 : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color.shade800,
                ),
              ),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 12, color: color.shade800)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _alert(IconData icon, MaterialColor color, String text, int? tab) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: tab == null ? null : () => widget.onNavigate(tab),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color.shade700),
              const SizedBox(width: 10),
              Expanded(
                child: Text(text, style: TextStyle(color: color.shade900)),
              ),
              if (tab != null) Icon(Icons.chevron_right, color: color.shade700),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rowCard(DashboardRow r) {
    final MaterialColor c = r.status == 'Leave'
        ? Colors.blue
        : r.status == 'NotYet'
        ? Colors.red
        : (r.isLate ? Colors.orange : Colors.green);
    final String tag = r.status == 'Leave' || r.status == 'NotYet'
        ? r.label
        : (r.isLate ? 'Đi trễ' : 'Đúng giờ');
    final String sub = r.checkIn == null
        ? "Mã: ${r.code}"
        : "Vào ${formatTime(r.checkIn!)} • Ra ${r.checkOut == null ? '--:--:--' : formatTime(r.checkOut!)}";
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: c.shade50,
          child: Text(
            initialOf(r.name),
            style: TextStyle(color: c.shade700, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(sub),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: c.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            tag,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: c.shade800,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final d = _data;
    if (_error != null || d == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScanPlaceholder(
                icon: Icons.cloud_off,
                text: _error ?? "Không tải được dữ liệu",
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text("Thử lại"),
              ),
            ],
          ),
        ),
      );
    }

    final rows = d.rows;
    final inCount = rows.where((r) => r.status == 'Working' || r.status == 'Done').length;
    final lateCount = rows.where((r) => r.isLate).length;
    final workingCount = rows.where((r) => r.status == 'Working').length;
    final doneCount = rows.where((r) => r.status == 'Done').length;
    final leaveCount = rows.where((r) => r.status == 'Leave').length;
    final notYetCount = rows.where((r) => r.status == 'NotYet').length;
    final shown = rows.where(_match).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Icon(Icons.today, color: Colors.indigo.shade400),
              const SizedBox(width: 8),
              Text(
                "${_weekdays[d.date.weekday - 1]}, ${formatDate(d.date)}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (d.holidayName != null)
            _alert(Icons.celebration, Colors.purple, "Hôm nay là ngày lễ: ${d.holidayName}", null),
          Row(
            children: [
              _statBox("Đã vào làm", "$inCount/${d.totalEmployees}", Colors.indigo, 'In'),
              const SizedBox(width: 10),
              _statBox("Đi trễ", "$lateCount", Colors.orange, 'Late'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _statBox("Đang làm", "$workingCount", Colors.green, 'Working'),
              const SizedBox(width: 10),
              _statBox("Đã về", "$doneCount", Colors.teal, 'Done'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _statBox("Nghỉ phép", "$leaveCount", Colors.blue, 'Leave'),
              const SizedBox(width: 10),
              _statBox("Chưa đến", "$notYetCount", Colors.red, 'NotYet'),
            ],
          ),
          const SizedBox(height: 16),
          if (d.pendingLeaves > 0)
            _alert(Icons.event_busy, Colors.orange,
                "${d.pendingLeaves} đơn nghỉ đang chờ duyệt", DashboardScreen.leaveTab),
          if (d.duplicateDevices > 0)
            _alert(Icons.warning_amber_rounded, Colors.red,
                "${d.duplicateDevices} máy đang bị dùng chung nhiều tài khoản",
                DashboardScreen.duplicateTab),
          if (d.missedCheckOutYesterday > 0)
            _alert(Icons.logout, Colors.deepOrange,
                "${d.missedCheckOutYesterday} người quên quét ra hôm qua", null),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.list_alt, size: 20, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              const Text("Chi tiết hôm nay",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_filter != 'All')
                TextButton(
                  onPressed: () => setState(() => _filter = 'All'),
                  child: const Text("Bỏ lọc"),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (shown.isEmpty)
            const ScanPlaceholder(
              icon: Icons.inbox_outlined,
              text: "Không có nhân viên nào trong nhóm này",
            )
          else
            for (final r in shown) ...[
              _rowCard(r),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}