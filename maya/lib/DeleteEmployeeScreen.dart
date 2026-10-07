import 'dart:async';

import 'package:flutter/material.dart';
import 'BluetoothService.dart';
import 'CommonWidgets.dart';
import 'EmployeeRepository.dart';

/// Tab 3: quét mã -> hỏi xác nhận -> xác nhận mới xóa
class DeleteEmployeeScreen extends StatefulWidget {
  const DeleteEmployeeScreen({super.key});

  @override
  State<DeleteEmployeeScreen> createState() => _DeleteEmployeeScreenState();
}

class _DeleteEmployeeScreenState extends State<DeleteEmployeeScreen> {
  final _repo = EmployeeRepository.instance;
  StreamSubscription<String>? _sub;

  bool _dialogOpen = false;
  int _count = 0;
  String? _invalidCode;
  String? _deletedName;
  String? _deletedCode;

  @override
  void initState() {
    super.initState();
    _sub = BluetoothService.instance.scans.listen(_onScan);
    _loadCount();
  }

  Future<void> _loadCount() async {
    final c = await _repo.count();
    if (mounted) setState(() => _count = c);
  }

  Future<void> _onScan(String code) async {
    if (_dialogOpen) return; // đang xử lý/hiện hộp thoại -> bỏ qua mã quét thêm
    _dialogOpen = true;

    final name = await _repo.getName(code);
    if (!mounted) return;
    if (name == null) {
      _dialogOpen = false;
      setState(() {
        _invalidCode = code;
        _deletedName = null;
        _deletedCode = null;
      });
      return;
    }

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
    _dialogOpen = false;

    if (!mounted) return;

    if (confirmed == true) {
      await _repo.delete(code);
      final c = await _repo.count();
      if (!mounted) return;
      setState(() {
        _count = c;
        _invalidCode = null;
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

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Widget _buildResult() {
    if (_invalidCode != null) return InvalidCodeCard(code: _invalidCode!);

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
      icon: Icons.qr_code_scanner,
      text: "Quét mã nhân viên bên Máy B\nđể xóa (sẽ có bước xác nhận)",
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ConnectionStatusCard(),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Chip(
              avatar: const Icon(Icons.groups, size: 18),
              label: Text("Hiện có $_count nhân viên"),
            ),
          ),
          const SizedBox(height: 8),
          _buildResult(),
        ],
      ),
    );
  }
}