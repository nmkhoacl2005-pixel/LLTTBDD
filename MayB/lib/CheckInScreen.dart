import 'dart:async';
import 'package:flutter/material.dart';
import 'AuthStorage.dart';
import 'BleClient.dart';
import 'EmpWidgets.dart';
import 'Protocol.dart';

/// Tab 1: nút Chấm công + kết quả (nội dung của tab, không có Scaffold)
class CheckInScreen extends StatefulWidget {
  const CheckInScreen({Key? key}) : super(key: key);

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  String _name = '';
  String _code = '';
  bool _busy = false;
  BleResult? _result;
  Timer? _resetTimer;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final n = await AuthStorage.name();
    final c = await AuthStorage.code();
    if (mounted) setState(() {
      _name = n ?? '';
      _code = c ?? '';
    });
  }

  Future<void> _checkIn() async {
    _resetTimer?.cancel();
    setState(() {
      _busy = true;
      _result = null;
    });
    final r = await BleClient.instance.checkIn();
    if (!mounted) return;

    if (!r.ok && r.error == kErrUnlinked) {
      await goActivate(context, 'Máy đã bị hủy liên kết, vui lòng kích hoạt lại');
      return;
    }
    setState(() {
      _busy = false;
      _result = r;
    });
    _resetTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _result = null);
    });
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  Widget _header() {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.indigo.shade50,
          child: Text(
            initialOf(_name),
            style: TextStyle(
                color: Colors.indigo.shade700, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        title: Text(_name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        subtitle: Text('Mã: $_code'),
      ),
    );
  }

  Widget _resultView() {
    if (_busy) {
      return const InfoPlaceholder(
        icon: Icons.bluetooth_searching,
        text: 'Đang tìm máy trạm...\n(hãy đứng gần máy trạm)',
      );
    }
    final r = _result;
    if (r == null) {
      return const InfoPlaceholder(
        icon: Icons.touch_app,
        text: 'Bấm "Chấm công" khi đứng gần máy trạm',
      );
    }

    if (!r.ok) {
      return _simpleCard(Colors.red, Icons.error_outline, r.error ?? 'Lỗi', null);
    }
    final t = r.time;
    if (r.done) {
      return _simpleCard(Colors.orange, Icons.block, 'Hôm nay đã chấm công ra',
          t != null ? 'Đã ra lúc ${formatTime(t)}' : null);
    }

    final st = r.status ?? '';
    final MaterialColor c = st.contains('trễ')
        ? Colors.orange
        : st.contains('sớm')
        ? Colors.deepOrange
        : Colors.green;
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
          BoxShadow(color: c.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8)),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              st,
              style: TextStyle(color: c.shade800, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          if (t != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: Colors.white38, height: 1),
            ),
            Text(
              formatTime(t),
              style: const TextStyle(
                  color: Colors.white, fontSize: 40, fontWeight: FontWeight.w300, letterSpacing: 2),
            ),
            Text(formatDate(t), style: const TextStyle(color: Colors.white70, fontSize: 15)),
          ],
        ],
      ),
    );
  }

  Widget _simpleCard(MaterialColor c, IconData icon, String title, String? sub) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 56, color: c),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: c.shade800),
          ),
          if (sub != null) ...[
            const SizedBox(height: 8),
            Text(sub, style: TextStyle(color: Colors.grey.shade800)),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          const SizedBox(height: 16),
          _resultView(),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _checkIn,
            icon: _busy
                ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.fingerprint),
            label: Text(_busy ? 'Đang chấm công...' : 'Chấm công',
                style: const TextStyle(fontSize: 17)),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}