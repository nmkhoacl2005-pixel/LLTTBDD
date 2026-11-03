import 'package:flutter/material.dart';
import 'CommonWidgets.dart';
import 'EmployeeRepository.dart';

/// Quản lý ngày lễ: ngày lễ không bị tính vắng, đi làm ngày lễ được nhân hệ số lương
class HolidayScreen extends StatefulWidget {
  const HolidayScreen({super.key});

  @override
  State<HolidayScreen> createState() => _HolidayScreenState();
}

class _HolidayScreenState extends State<HolidayScreen> {
  final _repo = EmployeeRepository.instance;

  int _year = DateTime.now().year;
  List<Holiday> _items = [];
  bool _loading = true;

  static const _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final year = _year;
    final list = await _repo.holidays(year: year);
    if (!mounted || year != _year) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  void _changeYear(int delta) {
    setState(() {
      _year += delta;
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

  Future<void> _add() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.year == _year ? now : DateTime(_year),
      firstDate: DateTime(_year),
      lastDate: DateTime(_year, 12, 31),
    );
    if (date == null || !mounted) return;

    final name = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _NameDialog(),
    );
    if (name == null || !mounted) return;

    final ok = await _repo.addHoliday(date, name);
    if (!mounted) return;
    if (!ok) {
      _snack("Ngày này đã có trong danh sách", Colors.red);
      return;
    }
    await _load();
  }

  Future<void> _delete(Holiday h) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 44),
        title: const Text("Xóa ngày lễ"),
        content: Text("${h.name} (${formatDate(h.date)})", textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    await _repo.deleteHoliday(h.id);
    await _load();
  }

  Widget _card(Holiday h) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Container(
          width: 52,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                two(h.date.day),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              Text(
                "Th${h.date.month}",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
        title: Text(h.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text("${_weekdays[h.date.weekday - 1]}, ${formatDate(h.date)}"),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _delete(h),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => _changeYear(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                "Năm $_year",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => _changeYear(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          FilledButton.tonalIcon(
            onPressed: _add,
            icon: const Icon(Icons.event_available),
            label: const Text("Thêm ngày lễ"),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _items.isEmpty
                ? const Center(
              child: ScanPlaceholder(
                icon: Icons.celebration_outlined,
                text: "Chưa có ngày lễ nào trong năm này",
              ),
            )
                : ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _card(_items[i]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hộp thoại nhập tên ngày lễ. Trả về tên khi Xác nhận, null khi Hủy
class _NameDialog extends StatefulWidget {
  const _NameDialog();

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _ctrl = TextEditingController();
  String? _error;

  void _confirm() {
    final name = _ctrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = "Vui lòng nhập tên ngày lễ");
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      scrollable: true,
      title: const Text("Tên ngày lễ"),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) => _confirm(),
        decoration: InputDecoration(
          labelText: "Ví dụ: Quốc khánh",
          errorText: _error,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Hủy"),
        ),
        FilledButton(onPressed: _confirm, child: const Text("Xác nhận")),
      ],
    );
  }
}