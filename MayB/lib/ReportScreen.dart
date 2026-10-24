import 'package:flutter/material.dart';
import 'BleClient.dart';
import 'EmpWidgets.dart';
import 'Protocol.dart';

/// Tab 2: báo cáo chấm công của chính mình theo tháng (lấy từ máy trạm qua BLE)
class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  List<DayRecord> _days = [];
  bool _loading = false;
  String? _error;

  static const _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _key(DateTime m) => '${m.year}-${m.month}';

  bool _isCurrent(DateTime m) {
    final now = DateTime.now();
    return m.year == now.year && m.month == now.month;
  }

  /// Tháng cũ dùng cache; tháng hiện tại luôn tải mới (dữ liệu còn thay đổi)
  Future<void> _load({bool force = false}) async {
    final month = _month;
    final cached = reportCache[_key(month)];
    if (!force && cached != null && !_isCurrent(month)) {
      setState(() {
        _days = cached;
        _error = null;
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    final r = await BleClient.instance.monthReport(month.year, month.month);
    if (!mounted || month != _month) return;

    if (!r.ok && r.error == kErrUnlinked) {
      await goActivate(context, 'Máy đã bị hủy liên kết, vui lòng kích hoạt lại');
      return;
    }
    setState(() {
      _loading = false;
      if (r.ok) {
        _days = r.days;
        reportCache[_key(month)] = r.days;
      } else {
        _days = [];
        _error = r.error ?? 'Không tải được báo cáo';
      }
    });
  }

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
    _load();
  }

  Widget _statBox(String label, int value, MaterialColor color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              "$value",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color.shade800),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: color.shade800)),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color.shade800),
      ),
    );
  }

  Widget _timeRow(String label, int? sec, String status, MaterialColor color) {
    return Row(
      children: [
        SizedBox(width: 36, child: Text(label, style: TextStyle(color: Colors.grey.shade600))),
        Text(
          sec == null ? "--:--:--" : formatSec(sec),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        _chip(status, color),
      ],
    );
  }

  Widget _dayCard(DayRecord d) {
    final date = DateTime(_month.year, _month.month, d.day);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    two(d.day),
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo.shade700),
                  ),
                  Text(
                    _weekdays[date.weekday - 1],
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                children: [
                  _timeRow("Vào", d.inSec, d.late ? 'Đi trễ' : 'Đúng giờ',
                      d.late ? Colors.orange : Colors.green),
                  const SizedBox(height: 8),
                  _timeRow(
                    "Ra",
                    d.outSec,
                    d.outSec == null ? 'Chưa quét ra' : (d.early ? 'Về sớm' : 'Ra đúng giờ'),
                    d.outSec == null
                        ? Colors.grey
                        : (d.early ? Colors.deepOrange : Colors.green),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: InfoPlaceholder(
          icon: Icons.bluetooth_searching,
          text: 'Đang lấy báo cáo từ máy trạm...\n(hãy đứng gần máy trạm)',
        ),
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
                onPressed: () => _load(force: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }
    if (_days.isEmpty) {
      return const Center(
        child: InfoPlaceholder(
          icon: Icons.event_busy,
          text: 'Chưa có dữ liệu chấm công tháng này',
        ),
      );
    }
    return ListView.separated(
      itemCount: _days.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _dayCard(_days[i]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lateCount = _days.where((d) => d.late).length;
    final earlyCount = _days.where((d) => d.early).length;

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
                onPressed: (_loading || _isCurrent(_month)) ? null : () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right),
              ),
              IconButton(
                tooltip: 'Tải lại',
                onPressed: _loading ? null : () => _load(force: true),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          Row(
            children: [
              _statBox("Ngày công", _days.length, Colors.indigo),
              const SizedBox(width: 10),
              _statBox("Đi trễ", lateCount, Colors.orange),
              const SizedBox(width: 10),
              _statBox("Về sớm", earlyCount, Colors.deepOrange),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: _body()),
        ],
      ),
    );
  }
}
