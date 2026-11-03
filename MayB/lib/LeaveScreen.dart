import 'package:flutter/material.dart';
import 'BleClient.dart';
import 'EmpWidgets.dart';
import 'Protocol.dart';

/// Tab 3: gửi đơn xin nghỉ và xem trạng thái các đơn đã gửi
class LeaveScreen extends StatefulWidget {
  const LeaveScreen({Key? key}) : super(key: key);

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  static const _types = ['Phép năm', 'Ốm', 'Không lương'];

  final _reasonCtrl = TextEditingController();
  DateTimeRange? _range;
  String _type = _types.first;
  bool _sending = false;
  bool _loading = true;
  String? _error;
  List<LeaveItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final r = await BleClient.instance.myLeaves();
    if (!mounted) return;
    if (!r.ok && r.error == kErrUnlinked) {
      await goActivate(context, 'Máy đã bị hủy liên kết, vui lòng kích hoạt lại');
      return;
    }
    setState(() {
      _loading = false;
      _items = r.items;
      _error = r.ok ? null : r.error;
    });
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

  Future<void> _pickRange() async {
    final today = DateTime.now();
    final first = DateTime(today.year, today.month, today.day);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: first,
      lastDate: first.add(const Duration(days: 365)),
      initialDateRange: _range,
    );
    if (picked != null && mounted) setState(() => _range = picked);
  }

  Future<void> _send() async {
    final range = _range;
    final reason = _reasonCtrl.text.trim();
    if (range == null) {
      _snack('Vui lòng chọn ngày nghỉ', Colors.red);
      return;
    }
    if (reason.isEmpty) {
      _snack('Vui lòng nhập lý do', Colors.red);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    final r = await BleClient.instance
        .sendLeave(range.start, range.end, _type, reason);
    if (!mounted) return;

    if (!r.ok && r.error == kErrUnlinked) {
      await goActivate(context, 'Máy đã bị hủy liên kết, vui lòng kích hoạt lại');
      return;
    }
    setState(() => _sending = false);
    if (!r.ok) {
      _snack(r.error ?? 'Gửi đơn thất bại', Colors.red);
      return;
    }
    _snack('Đã gửi đơn, chờ quản lý duyệt', Colors.green);
    setState(() {
      _range = null;
      _reasonCtrl.clear();
    });
    _load();
  }

  Widget _form() {
    final range = _range;
    return Card(
      elevation: 3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Đơn xin nghỉ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _sending ? null : _pickRange,
              icon: const Icon(Icons.date_range),
              label: Text(range == null
                  ? 'Chọn ngày nghỉ'
                  : '${formatDate(range.start)} - ${formatDate(range.end)}'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: InputDecoration(
                labelText: 'Loại nghỉ',
                prefixIcon: const Icon(Icons.category_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: _sending ? null : (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonCtrl,
              enabled: !_sending,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Lý do',
                prefixIcon: const Icon(Icons.edit_note),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send),
              label: Text(_sending ? 'Đang gửi...' : 'Gửi đơn'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String status) {
    final MaterialColor c = status == 'Approved'
        ? Colors.green
        : status == 'Rejected'
        ? Colors.red
        : Colors.orange;
    final label = status == 'Approved'
        ? 'Đã duyệt'
        : status == 'Rejected'
        ? 'Từ chối'
        : 'Chờ duyệt';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.shade800)),
    );
  }

  Widget _itemCard(LeaveItem l) {
    final range = l.days == 1
        ? formatDate(l.from)
        : '${formatDate(l.from)} - ${formatDate(l.to)}';
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        title: Text('$range (${l.days} ngày)',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${l.type} • ${l.reason}'),
        trailing: _chip(l.status),
      ),
    );
  }

  Widget _list() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return InfoPlaceholder(
          icon: Icons.error_outline, color: Colors.red.shade200, text: _error!);
    }
    if (_items.isEmpty) {
      return const InfoPlaceholder(
          icon: Icons.inbox_outlined, text: 'Bạn chưa gửi đơn nghỉ nào');
    }
    return Column(
      children: [
        for (final l in _items) ...[
          _itemCard(l),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _form(),
          const SizedBox(height: 20),
          const Text('Đơn đã gửi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _list(),
        ],
      ),
    );
  }
}