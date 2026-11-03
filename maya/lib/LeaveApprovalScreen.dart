import 'package:flutter/material.dart';
import 'ApiClient.dart';
import 'CommonWidgets.dart';
import 'EmployeeRepository.dart';

/// Quản lý duyệt đơn xin nghỉ của nhân viên
class LeaveApprovalScreen extends StatefulWidget {
  const LeaveApprovalScreen({super.key});

  @override
  State<LeaveApprovalScreen> createState() => _LeaveApprovalScreenState();
}

class _LeaveApprovalScreenState extends State<LeaveApprovalScreen> {
  final _repo = EmployeeRepository.instance;

  String _status = 'Pending';
  List<LeaveRequest> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final status = _status;
    final list = await _repo.leaves(status: status);
    if (!mounted || status != _status) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  void _select(String status) {
    setState(() {
      _status = status;
      _loading = true;
    });
    _load();
  }

  void _snack(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _process(LeaveRequest l, bool approve) async {
    try {
      if (approve) {
        await _repo.approveLeave(l.id);
      } else {
        await _repo.rejectLeave(l.id);
      }
    } on ApiException catch (e) {
      if (mounted) _snack(e.message, Colors.red);
    }
    if (mounted) await _load();
  }

  Widget _card(LeaveRequest l) {
    final sameDay = l.days == 1;
    final range = sameDay
        ? formatDate(l.fromDate)
        : "${formatDate(l.fromDate)} - ${formatDate(l.toDate)}";
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.indigo.shade50,
                  child: Text(
                    initialOf(l.name),
                    style: TextStyle(
                      color: Colors.indigo.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text("Mã: ${l.code}",
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Chip(label: Text(l.type)),
              ],
            ),
            const SizedBox(height: 10),
            Text("$range (${l.days} ngày)",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(l.reason, style: TextStyle(color: Colors.grey.shade800)),
            if (l.status == 'Pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _process(l, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text("Từ chối"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _process(l, true),
                      child: const Text("Duyệt"),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Pending', label: Text("Chờ duyệt")),
              ButtonSegment(value: 'Approved', label: Text("Đã duyệt")),
              ButtonSegment(value: 'Rejected', label: Text("Từ chối")),
            ],
            selected: {_status},
            onSelectionChanged: (s) => _select(s.first),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  ScanPlaceholder(
                    icon: Icons.inbox_outlined,
                    text: "Không có đơn nghỉ nào",
                  ),
                ],
              )
                  : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _items.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 8),
                itemBuilder: (context, i) => _card(_items[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}