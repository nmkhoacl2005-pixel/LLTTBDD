import 'package:flutter/material.dart';
import 'CommonWidgets.dart';
import 'EmployeeRepository.dart';
import 'WorkSchedule.dart';

/// Tab 4: chi tiết chấm công của 1 nhân viên theo tháng
class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  final _repo = EmployeeRepository.instance;
  final _schedule = WorkSchedule.instance;

  String? _code;
  List<MapEntry<String, String>> _employees = [];
  List<DaySummary> _days = [];
  bool _loading = true;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  static const _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final employees = await _repo.employees();
    if (!mounted) return;
    _employees = employees;
    _code = employees.isEmpty ? null : employees.first.key;
    await _loadDays();
  }

  Future<void> _loadDays() async {
    final code = _code;
    final month = _month;
    if (code == null) {
      setState(() => _loading = false);
      return;
    }
    final days = await _repo.monthSummary(code, month.year, month.month);
    if (!mounted || code != _code || month != _month) return; // bỏ kết quả cũ
    setState(() {
      _days = days;
      _loading = false;
    });
  }

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
    _loadDays();
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
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color.shade800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: color.shade800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(StatusInfo st) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: st.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        st.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: st.color.shade800,
        ),
      ),
    );
  }

  Widget _timeRow(String label, DateTime? time, StatusInfo status) {
    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
        ),
        Text(
          time == null ? "--:--:--" : formatTime(time),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        _chip(status),
      ],
    );
  }

  Widget _dayCard(DaySummary d) {
    final inStatus = _schedule.inStatus(d.checkIn);
    final StatusInfo outStatus = d.checkOut == null
        ? const StatusInfo('Chưa quét ra', Colors.grey)
        : _schedule.outStatus(d.checkOut!);

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
                    two(d.date.day),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade700,
                    ),
                  ),
                  Text(
                    _weekdays[d.date.weekday - 1],
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                children: [
                  _timeRow("Vào", d.checkIn, inStatus),
                  const SizedBox(height: 8),
                  _timeRow("Ra", d.checkOut, outStatus),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final employees = _employees;
    if (employees.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: ScanPlaceholder(
          icon: Icons.people_outline,
          text: "Chưa có nhân viên nào",
        ),
      );
    }

    final days = _days;
    final lateCount = days.where((d) => _schedule.isLate(d.checkIn)).length;
    final earlyCount = days
        .where((d) => d.checkOut != null && _schedule.isEarlyLeave(d.checkOut!))
        .length;

    final now = DateTime.now();
    final isCurrentMonth = _month.year == now.year && _month.month == now.month;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            value: _code,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: "Nhân viên",
              prefixIcon: const Icon(Icons.person_search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: employees
                .map((e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(
                        "${e.value} (${e.key})",
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: (v) {
              setState(() => _code = v);
              _loadDays();
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                "Tháng ${two(_month.month)}/${_month.year}",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: isCurrentMonth ? null : () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Row(
            children: [
              _statBox("Ngày công", days.length, Colors.indigo),
              const SizedBox(width: 10),
              _statBox("Đi trễ", lateCount, Colors.orange),
              const SizedBox(width: 10),
              _statBox("Về sớm", earlyCount, Colors.deepOrange),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: days.isEmpty
                ? const Center(
                    child: ScanPlaceholder(
                      icon: Icons.event_busy,
                      text: "Chưa có dữ liệu chấm công tháng này",
                    ),
                  )
                : ListView.separated(
                    itemCount: days.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _dayCard(days[i]),
                  ),
          ),
        ],
      ),
    );
  }
}
