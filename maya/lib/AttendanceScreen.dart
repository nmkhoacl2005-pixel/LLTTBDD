import 'dart:async';

import 'package:flutter/material.dart';
import 'BluetoothService.dart';
import 'CommonWidgets.dart';
import 'EmployeeRepository.dart';
import 'WorkSchedule.dart';

/// Tab 1: nhận mã từ Máy B -> hiện tên + giờ chấm công
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _repo = EmployeeRepository.instance;
  final _schedule = WorkSchedule.instance;
  StreamSubscription<String>? _sub;

  AttendanceRecord? _last;
  bool _alreadyDone = false;
  String? _invalidCode;
  Timer? _resetTimer;
  List<AttendanceRecord> _history = [];

  @override
  void initState() {
    super.initState();
    _sub = BluetoothService.instance.scans.listen(_onScan);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await _repo.history();
    if (mounted) setState(() => _history = list);
  }

  Future<void> _onScan(String code) async {
    final name = await _repo.getName(code);
    final ScanResult? result =
    name == null ? null : await _repo.addScan(code, name, DateTime.now());
    final list = await _repo.history();
    if (!mounted) return;
    setState(() {
      _history = list;
      if (result != null) {
        _last = result.record;
        _alreadyDone = result.alreadyDone;
        _invalidCode = null;
      } else {
        _last = null;
        _alreadyDone = false;
        _invalidCode = code;
      }
    });
    _startResetTimer();
  }

  /// Sau 5 giây tự xóa thông báo, quay về trạng thái chờ quét
  void _startResetTimer() {
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() {
        _last = null;
        _alreadyDone = false;
        _invalidCode = null;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _resetTimer?.cancel();
    super.dispose();
  }

  Widget _buildAlreadyDone(AttendanceRecord r) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          const Icon(Icons.block, size: 56, color: Colors.orange),
          const SizedBox(height: 12),
          Text(
            "Hôm nay đã chấm công ra",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            r.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          Text(
            "Mã: ${r.code}",
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            "Đã ra lúc ${formatTime(r.time)}",
            style: TextStyle(color: Colors.grey.shade800),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    if (_invalidCode != null) return InvalidCodeCard(code: _invalidCode!);
    if (_last == null) {
      return const ScanPlaceholder(
        icon: Icons.qr_code_scanner,
        text: "Đang chờ Máy B quét mã nhân viên...",
      );
    }

    final r = _last!;
    if (_alreadyDone) return _buildAlreadyDone(r);
    final st = r.isCheckIn
        ? _schedule.inStatus(r.time)
        : _schedule.outStatus(r.time);
    final MaterialColor c = st.color;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.shade600, c.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: c.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 52),
          const SizedBox(height: 8),
          Text(
            "${r.isCheckIn ? 'Vào ca' : 'Ra ca'} thành công",
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 12),
          Text(
            r.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Mã: ${r.code}",
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              st.label,
              style: TextStyle(
                color: c.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white38, height: 1),
          ),
          Text(
            formatTime(r.time),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w300,
              letterSpacing: 2,
            ),
          ),
          Text(
            formatDate(r.time),
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    final list = _history;
    if (list.isEmpty) {
      return Center(
        child: Text(
          "Chưa có lượt chấm công nào",
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }
    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final r = list[i];
        final st = r.isCheckIn
            ? _schedule.inStatus(r.time)
            : _schedule.outStatus(r.time);
        return Card(
          margin: EdgeInsets.zero,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.indigo.shade50,
              child: Text(
                initialOf(r.name),
                style: TextStyle(
                  color: Colors.indigo.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              "${r.code} • ${r.isCheckIn ? 'Vào' : 'Ra'} • ${st.label}",
              style: TextStyle(color: st.color.shade700),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatTime(r.time),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  formatDate(r.time),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ConnectionStatusCard(),
          const SizedBox(height: 16),
          _buildResult(),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.history, size: 20, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              const Text(
                "Lịch sử chấm công",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildHistory()),
        ],
      ),
    );
  }
}