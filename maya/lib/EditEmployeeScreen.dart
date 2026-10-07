import 'dart:async';

import 'package:flutter/material.dart';
import 'BluetoothService.dart';
import 'CommonWidgets.dart';
import 'EmployeeRepository.dart';

/// Tab 2: quét mã -> hiện mã + tên nhân viên -> cho phép sửa tên
class EditEmployeeScreen extends StatefulWidget {
  const EditEmployeeScreen({super.key});

  @override
  State<EditEmployeeScreen> createState() => _EditEmployeeScreenState();
}

class _EditEmployeeScreenState extends State<EditEmployeeScreen> {
  final _repo = EmployeeRepository.instance;
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  StreamSubscription<String>? _sub;

  String? _code; // mã nhân viên đang sửa
  String? _invalidCode;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _sub = BluetoothService.instance.scans.listen(_onScan);
  }

  Future<void> _onScan(String code) async {
    final name = await _repo.getName(code);
    if (!mounted) return;
    setState(() {
      _nameError = null;
      if (name == null) {
        _code = null;
        _invalidCode = code;
      } else {
        _invalidCode = null;
        _code = code;
        _codeCtrl.text = code;
        _nameCtrl.text = name;
      }
    });
  }

  Future<void> _save() async {
    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty) {
      setState(() => _nameError = "Tên không được để trống");
      return;
    }
    await _repo.updateName(_code!, newName);
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    setState(() => _nameError = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Đã cập nhật: $newName"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _cancel() {
    FocusScope.of(context).unfocus();
    setState(() {
      _code = null;
      _nameError = null;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Widget _buildForm() {
    return Card(
      elevation: 3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.indigo.shade50,
                  child: Icon(Icons.edit, color: Colors.indigo.shade700),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    "Sửa thông tin nhân viên",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeCtrl,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Mã nhân viên",
                prefixIcon: const Icon(Icons.badge_outlined),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: "Tên nhân viên",
                prefixIcon: const Icon(Icons.person_outline),
                errorText: _nameError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Hủy"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text("Lưu thay đổi"),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
          const ConnectionStatusCard(),
          const SizedBox(height: 16),
          if (_invalidCode != null)
            InvalidCodeCard(code: _invalidCode!)
          else if (_code == null)
            const ScanPlaceholder(
              icon: Icons.qr_code_scanner,
              text: "Quét mã nhân viên bên Máy B\nđể chỉnh sửa thông tin",
            )
          else
            _buildForm(),
        ],
      ),
    );
  }
}