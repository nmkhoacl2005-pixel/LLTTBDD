import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'BluetoothService.dart';
import 'CommonWidgets.dart';
import 'EmployeeRepository.dart';

/// Mã nhân viên hợp lệ: chỉ gồm chữ số, dài 10 đến 12 ký tự
final RegExp _employeeCodeRule = RegExp(r'^\d{10,12}$');

/// Tab 2: quét mã số mới (10-12 chữ số) -> nhập tên -> xác nhận để thêm nhân viên,
/// hoặc bấm "Thêm thủ công" để tự nhập mã số + tên
class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _repo = EmployeeRepository.instance;
  StreamSubscription<String>? _sub;

  bool _busy = false; // đang xử lý / đang hiện hộp thoại -> bỏ qua mã quét thêm
  int _count = 0;

  String? _invalidCode;
  String? _existsCode;
  String? _existsName;
  String? _addedCode;
  String? _addedName;

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

  void _clearResult() {
    _invalidCode = null;
    _existsCode = null;
    _existsName = null;
    _addedCode = null;
    _addedName = null;
  }

  Future<void> _onScan(String code) async {
    if (_busy) return;
    _busy = true;

    // 1. Kiểm tra định dạng: 10-12 chữ số
    if (!_employeeCodeRule.hasMatch(code)) {
      _busy = false;
      setState(() {
        _clearResult();
        _invalidCode = code;
      });
      return;
    }

    // 2. Mã đã có trong hệ thống?
    final existing = await _repo.getName(code);
    if (!mounted) return;
    if (existing != null) {
      _busy = false;
      setState(() {
        _clearResult();
        _existsCode = code;
        _existsName = existing;
      });
      return;
    }

    // 3. Mã mới -> hiện thông báo yêu cầu nhập tên
    final name = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _NameDialog(code: code),
    );
    _busy = false;
    if (!mounted) return;

    if (name == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đã hủy thêm nhân viên"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 4. Đã xác nhận -> lưu vào SQLite
    await _save(code, name);
  }

  /// Thêm thủ công: nhập cả mã số và tên
  Future<void> _addManually() async {
    if (_busy) return;
    _busy = true; // trong lúc nhập tay, bỏ qua mã quét từ Máy B
    final result = await showDialog<_NewEmployee>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ManualAddDialog(),
    );
    _busy = false;
    if (!mounted || result == null) return;
    await _save(result.code, result.name);
  }

  /// Lưu nhân viên vào SQLite rồi hiện thẻ kết quả (dùng cho cả quét mã và thêm thủ công)
  Future<void> _save(String code, String name) async {
    final ok = await _repo.addEmployee(code, name);
    final c = await _repo.count();
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Không thể thêm nhân viên (mã đã tồn tại)"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _clearResult();
      _addedCode = code;
      _addedName = name;
      _count = c;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Widget _resultCard({
    required IconData icon,
    required MaterialColor color,
    required String title,
    required String name,
    required String code,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 56, color: color),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          Text(
            "Mã: $code",
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    if (_invalidCode != null) {
      return InvalidCodeCard(
        code: _invalidCode!,
        hint: "Mã nhân viên phải gồm 10–12 chữ số",
      );
    }
    if (_existsName != null) {
      return _resultCard(
        icon: Icons.info_outline,
        color: Colors.orange,
        title: "Mã đã tồn tại",
        name: _existsName!,
        code: _existsCode!,
      );
    }
    if (_addedName != null) {
      return _resultCard(
        icon: Icons.person_add_alt_1,
        color: Colors.green,
        title: "Đã thêm nhân viên",
        name: _addedName!,
        code: _addedCode!,
      );
    }
    return const ScanPlaceholder(
      icon: Icons.person_add_alt_1,
      text: "Quét mã số nhân viên mới bên Máy B\n(10–12 chữ số) để thêm vào hệ thống",
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
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: _addManually,
            icon: const Icon(Icons.edit_note),
            label: const Text("Thêm thủ công"),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hộp thoại yêu cầu nhập tên, trả về tên (đã trim) khi bấm Xác nhận, null khi Hủy
class _NameDialog extends StatefulWidget {
  final String code;

  const _NameDialog({required this.code});

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _ctrl = TextEditingController();
  String? _error;

  void _confirm() {
    final name = _ctrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = "Vui lòng nhập tên nhân viên");
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
      icon: Icon(Icons.person_add_alt_1,
          color: Colors.indigo.shade600, size: 44),
      title: const Text("Thêm nhân viên mới"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Mã số: ${widget.code}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            "Mã này chưa có trong hệ thống.\nVui lòng nhập tên nhân viên:",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _confirm(),
            decoration: InputDecoration(
              labelText: "Tên nhân viên",
              prefixIcon: const Icon(Icons.person_outline),
              errorText: _error,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Hủy"),
        ),
        FilledButton(
          onPressed: _confirm,
          child: const Text("Xác nhận"),
        ),
      ],
    );
  }
}

class _NewEmployee {
  final String code;
  final String name;

  const _NewEmployee(this.code, this.name);
}

/// Hộp thoại nhập tay mã số + tên. Trả về _NewEmployee khi Xác nhận, null khi Hủy
class _ManualAddDialog extends StatefulWidget {
  const _ManualAddDialog();

  @override
  State<_ManualAddDialog> createState() => _ManualAddDialogState();
}

class _ManualAddDialogState extends State<_ManualAddDialog> {
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String? _codeError;
  String? _nameError;
  bool _checking = false;

  Future<void> _confirm() async {
    final code = _codeCtrl.text.trim();
    final name = _nameCtrl.text.trim();

    String? codeError;
    String? nameError;
    if (!_employeeCodeRule.hasMatch(code)) {
      codeError = "Mã phải gồm 10–12 chữ số";
    }
    if (name.isEmpty) {
      nameError = "Vui lòng nhập tên nhân viên";
    }

    if (codeError == null) {
      setState(() => _checking = true);
      final existing = await EmployeeRepository.instance.getName(code);
      if (!mounted) return;
      if (existing != null) codeError = "Mã đã tồn tại ($existing)";
    }

    if (codeError != null || nameError != null) {
      setState(() {
        _checking = false;
        _codeError = codeError;
        _nameError = nameError;
      });
      return;
    }

    Navigator.pop(context, _NewEmployee(code, name));
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      scrollable: true,
      icon: Icon(Icons.edit_note, color: Colors.indigo.shade600, size: 44),
      title: const Text("Thêm nhân viên thủ công"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _codeCtrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
            ],
            decoration: InputDecoration(
              labelText: "Mã nhân viên (10–12 chữ số)",
              prefixIcon: const Icon(Icons.badge_outlined),
              errorText: _codeError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _confirm(),
            decoration: InputDecoration(
              labelText: "Tên nhân viên",
              prefixIcon: const Icon(Icons.person_outline),
              errorText: _nameError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          onPressed: _checking ? null : () => Navigator.pop(context),
          child: const Text("Hủy"),
        ),
        FilledButton(
          onPressed: _checking ? null : _confirm,
          child: const Text("Xác nhận"),
        ),
      ],
    );
  }
}