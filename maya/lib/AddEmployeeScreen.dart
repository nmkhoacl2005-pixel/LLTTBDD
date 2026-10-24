import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'CommonWidgets.dart';
import 'EmployeeRepository.dart';

/// Mã nhân viên hợp lệ: chỉ gồm chữ số, dài 10 đến 12 ký tự
final RegExp _employeeCodeRule = RegExp(r'^\d{10,12}$');

/// Tab 2: bấm "Thêm thủ công" -> nhập mã số + tên + mật khẩu -> lưu nhân viên mới
class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _repo = EmployeeRepository.instance;

  int _count = 0;
  String? _addedCode;
  String? _addedName;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    final c = await _repo.count();
    if (mounted) setState(() => _count = c);
  }

  /// Thêm thủ công: nhập mã số, tên và mật khẩu
  Future<void> _addManually() async {
    final result = await showDialog<_NewEmployee>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ManualAddDialog(),
    );
    if (!mounted || result == null) return;
    await _save(result);
  }

  /// Lưu nhân viên vào SQLite rồi hiện thẻ kết quả
  Future<void> _save(_NewEmployee e) async {
    final ok = await _repo.addEmployee(e.code, e.name, password: e.password);
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
      _addedCode = e.code;
      _addedName = e.name;
      _count = c;
    });
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
      text: "Bấm \"Thêm thủ công\" để nhập mã số (10–12 chữ số),\ntên và mật khẩu cho nhân viên mới",
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

class _NewEmployee {
  final String code;
  final String name;
  final String password;

  const _NewEmployee(this.code, this.name, this.password);
}

/// Hộp thoại nhập mã số + tên + mật khẩu. Trả về _NewEmployee khi Xác nhận, null khi Hủy
class _ManualAddDialog extends StatefulWidget {
  const _ManualAddDialog();

  @override
  State<_ManualAddDialog> createState() => _ManualAddDialogState();
}

class _ManualAddDialogState extends State<_ManualAddDialog> {
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _codeError;
  String? _nameError;
  String? _passError;
  bool _checking = false;
  bool _hidePass = true;

  Future<void> _confirm() async {
    final code = _codeCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final pass = _passCtrl.text;

    String? codeError;
    String? nameError;
    String? passError;
    if (!_employeeCodeRule.hasMatch(code)) {
      codeError = "Mã phải gồm 10–12 chữ số";
    }
    if (name.isEmpty) {
      nameError = "Vui lòng nhập tên nhân viên";
    }
    if (pass.length < kMinPasswordLength) {
      passError = "Mật khẩu tối thiểu $kMinPasswordLength ký tự";
    }

    if (codeError == null) {
      setState(() => _checking = true);
      final existing = await EmployeeRepository.instance.getName(code);
      if (!mounted) return;
      if (existing != null) codeError = "Mã đã tồn tại ($existing)";
    }

    if (codeError != null || nameError != null || passError != null) {
      setState(() {
        _checking = false;
        _codeError = codeError;
        _nameError = nameError;
        _passError = passError;
      });
      return;
    }

    Navigator.pop(context, _NewEmployee(code, name, pass));
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _passCtrl.dispose();
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
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: "Tên nhân viên",
              prefixIcon: const Icon(Icons.person_outline),
              errorText: _nameError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passCtrl,
            obscureText: _hidePass,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _confirm(),
            decoration: InputDecoration(
              labelText: "Mật khẩu (tối thiểu $kMinPasswordLength ký tự)",
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                    _hidePass ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _hidePass = !_hidePass),
              ),
              errorText: _passError,
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