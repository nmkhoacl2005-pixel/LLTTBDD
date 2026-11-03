import 'package:flutter/material.dart';
import 'BleClient.dart';
import 'EmpWidgets.dart';
import 'Protocol.dart';

/// Tab 4: phiếu lương của chính mình theo tháng
class PayslipScreen extends StatefulWidget {
  const PayslipScreen({Key? key}) : super(key: key);

  @override
  State<PayslipScreen> createState() => _PayslipScreenState();
}

class _PayslipScreenState extends State<PayslipScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  Payslip? _slip;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get _isCurrent {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  Future<void> _load() async {
    final month = _month;
    setState(() {
      _loading = true;
      _error = null;
    });
    final r = await BleClient.instance.payslip(month.year, month.month);
    if (!mounted || month != _month) return;

    if (!r.ok && r.error == kErrUnlinked) {
      await goActivate(context, 'Máy đã bị hủy liên kết, vui lòng kích hoạt lại');
      return;
    }
    setState(() {
      _loading = false;
      _slip = r.ok ? r.slip : null;
      _error = r.ok ? null : (r.error ?? 'Không tải được phiếu lương');
    });
  }

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
    _load();
  }

  String _money(double v) {
    final s = v.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return "$buf đ";
  }

  String _h(double v) =>
      v == v.roundToDouble() ? "${v.toInt()} giờ" : "${v.toStringAsFixed(2)} giờ";

  Widget _line(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: Colors.grey.shade700))),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _totalCard(Payslip s) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade600, Colors.indigo.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _isCurrent ? "Tổng lương (tạm tính đến hôm nay)" : "Tổng lương",
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            _money(s.gross),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.hourlyRate == 0 ? "Chưa có lương giờ" : "Lương giờ: ${_money(s.hourlyRate)}",
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _detailCard(Payslip s) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          children: [
            _line("Ngày công", "${s.workDays}"),
            _line("Giờ làm thường", _h(s.regularHours)),
            _line("Giờ làm thêm (x1.5)", _h(s.otHours)),
            _line("Giờ làm cuối tuần (x2)", _h(s.weekendHours)),
            _line("Giờ làm ngày lễ (x3)", _h(s.holidayWorkedHours)),
            _line("Ngày lễ hưởng lương", _h(s.holidayPaidHours)),
            _line("Nghỉ có lương", "${s.paidLeaveDays} ngày (${_h(s.paidLeaveHours)})"),
            _line("Nghỉ không lương", "${s.unpaidLeaveDays} ngày"),
            _line("Phép năm đã dùng", "${s.annualLeaveUsed}/${s.annualLeaveQuota} ngày"),
            _line("Vắng không phép", "${s.absentDays} ngày",
                color: s.absentDays > 0 ? Colors.red : null),
            if (s.missingCheckOut > 0)
              _line("Thiếu giờ ra (tính 0 giờ)", "${s.missingCheckOut} ngày",
                  color: Colors.orange.shade800),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: InfoPlaceholder(icon: Icons.payments_outlined, text: 'Đang tải phiếu lương...'),
      );
    }
    if (_error != null) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              InfoPlaceholder(
                  icon: Icons.error_outline, color: Colors.red.shade200, text: _error!),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }
    final s = _slip;
    if (s == null) return const SizedBox();

    return ListView(
      children: [
        _totalCard(s),
        if (s.hourlyRate == 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.4)),
            ),
            child: Text(
              'Quản lý chưa đặt lương giờ cho bạn nên tổng lương đang là 0.',
              style: TextStyle(color: Colors.orange.shade900),
            ),
          ),
        ],
        const SizedBox(height: 16),
        _detailCard(s),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _loading ? null : () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                "Tháng ${two(_month.month)}/${_month.year}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: (_loading || _isCurrent) ? null : () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right),
              ),
              IconButton(
                tooltip: 'Tải lại',
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }
}