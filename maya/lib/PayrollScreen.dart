import 'package:flutter/material.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'ApiClient.dart';
import 'CommonWidgets.dart';
import 'EmployeeRepository.dart';

/// Bảng lương tháng của toàn bộ nhân viên
class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  final _repo = EmployeeRepository.instance;

  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  List<PayrollRow> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final month = _month;
    final rows = await _repo.payroll(month.year, month.month);
    if (!mounted || month != _month) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _loading = true;
    });
    _load();
  }

  Future<void> _export() async {
    final bytes = await ApiClient.instance.getBytes('/api/payroll/export',
        query: {'year': '${_month.year}', 'month': '${_month.month}'});
    final dir = (Platform.isAndroid ? await getExternalStorageDirectory() : null) ??
        await getApplicationDocumentsDirectory();
    final file =
    File('${dir.path}/BangLuong_${_month.year}_${two(_month.month)}.xlsx');
    await file.writeAsBytes(bytes, flush: true);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Đã lưu: ${file.path}')));
    await OpenFilex.open(file.path);
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: Colors.grey.shade700))),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _card(PayrollRow r) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
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
          r.hourlyRate == 0
              ? "Chưa đặt lương giờ"
              : "${_money(r.hourlyRate)}/giờ",
          style: TextStyle(
            color: r.hourlyRate == 0 ? Colors.red : Colors.grey.shade600,
          ),
        ),
        trailing: Text(
          _money(r.gross),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.indigo.shade700,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: [
          _line("Ngày công", "${r.workDays}"),
          _line("Giờ làm thường", _h(r.regularHours)),
          _line("Giờ làm thêm (x1.5)", _h(r.otHours)),
          _line("Giờ làm cuối tuần (x2)", _h(r.weekendHours)),
          _line("Giờ làm ngày lễ (x3)", _h(r.holidayWorkedHours)),
          _line("Ngày lễ hưởng lương", _h(r.holidayPaidHours)),
          _line("Nghỉ có lương", "${r.paidLeaveDays} ngày (${_h(r.paidLeaveHours)})"),
          _line("Nghỉ không lương", "${r.unpaidLeaveDays} ngày"),
          _line("Phép năm đã dùng", "${r.annualLeaveUsed}/${r.annualLeaveQuota} ngày"),
          _line("Vắng không phép", "${r.absentDays} ngày",
              color: r.absentDays > 0 ? Colors.red : null),
          if (r.missingCheckOut > 0)
            _line("Thiếu giờ ra (tính 0 giờ)", "${r.missingCheckOut} ngày",
                color: Colors.orange.shade800),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final now = DateTime.now();
    final isCurrent = _month.year == now.year && _month.month == now.month;
    final total = _rows.fold<double>(0, (sum, r) => sum + r.gross);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                "Tháng ${two(_month.month)}/${_month.year}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: isCurrent ? null : () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right),
              ),
              IconButton(
                tooltip: "Xuất Excel",
                onPressed: _rows.isEmpty ? null : _export,
                icon: const Icon(Icons.file_download),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.payments, color: Colors.indigo),
                const SizedBox(width: 12),
                const Expanded(child: Text("Tổng chi lương tháng")),
                Text(
                  _money(total),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _rows.isEmpty
                ? const Center(
              child: ScanPlaceholder(
                icon: Icons.people_outline,
                text: "Chưa có nhân viên nào",
              ),
            )
                : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _card(_rows[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}