import 'package:flutter/material.dart';
import 'CommonWidgets.dart';
import 'EmployeeRepository.dart';

/// Tab 4: chọn nhân viên từ danh sách -> hỏi xác nhận -> xác nhận mới xóa
class DeleteEmployeeScreen extends StatefulWidget {
  const DeleteEmployeeScreen({super.key});

  @override
  State<DeleteEmployeeScreen> createState() => _DeleteEmployeeScreenState();
}

class _DeleteEmployeeScreenState extends State<DeleteEmployeeScreen> {
  final _repo = EmployeeRepository.instance;

  List<MapEntry<String, String>> _employees = [];
  String? _code; // nhân viên đang chọn
  int _count = 0;
  String? _deletedName;
  String? _deletedCode;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final list = await _repo.employees();
    if (!mounted) return;
    setState(() {
      _employees = list;
      _count = list.length;
    });
  }

  Future<void> _delete() async {
    final code = _code;
    if (code == null) return;
    final name = await _repo.getName(code);
    if (!mounted || name == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.warning_amber_rounded,
            color: Colors.red, size: 48),
        title: const Text("Xác nhận xóa nhân viên"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Bạn có chắc chắn muốn xóa nhân viên:"),
            const SizedBox(height: 12),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text("Mã: $code", style: TextStyle(color: Colors.grey.shade700)),
          ],
        ),
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

    if (!mounted) return;

    if (confirmed == true) {
      await _repo.delete(code);
      final list = await _repo.employees();
      if (!mounted) return;
      setState(() {
        _employees = list;
        _count = list.length;
        _code = null;
        _deletedName = name;
        _deletedCode = code;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đã hủy xóa"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildResult() {
    if (_deletedName != null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            const Icon(Icons.delete_forever, size: 56, color: Colors.red),
            const SizedBox(height: 12),
            const Text(
              "Đã xóa nhân viên",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _deletedName!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              "Mã: $_deletedCode",
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      );
    }

    return const ScanPlaceholder(
      icon: Icons.delete_outline,
      text: "Chọn nhân viên cần xóa ở trên\n(sẽ có bước xác nhận)",
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Chip(
              avatar: const Icon(Icons.groups, size: 18),
              label: Text("Hiện có $_count nhân viên"),
            ),
          ),
          const SizedBox(height: 8),
          if (_employees.isEmpty)
            const ScanPlaceholder(
              icon: Icons.people_outline,
              text: "Chưa có nhân viên nào",
            )
          else ...[
            EmployeePicker(
              employees: _employees,
              value: _code,
              onChanged: (v) => setState(() => _code = v),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _code == null ? null : _delete,
              icon: const Icon(Icons.delete),
              label: const Text("Xóa nhân viên"),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildResult(),
          ],
        ],
      ),
    );
  }
}