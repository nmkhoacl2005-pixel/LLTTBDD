import 'package:flutter/material.dart';
import 'CommonWidgets.dart';
import 'EmployeeRepository.dart';

/// Tab 3: chọn nhân viên từ danh sách -> sửa tên, đặt lại mật khẩu, hủy liên kết máy
class EditEmployeeScreen extends StatefulWidget {
  const EditEmployeeScreen({super.key});

  @override
  State<EditEmployeeScreen> createState() => _EditEmployeeScreenState();
}

class _EditEmployeeScreenState extends State<EditEmployeeScreen> {
  final _repo = EmployeeRepository.instance;
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  List<MapEntry<String, String>> _employees = [];
  String? _code; // mã nhân viên đang sửa
  bool _bound = false; // nhân viên đã liên kết điện thoại chưa
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final list = await _repo.employees();
    if (mounted) setState(() => _employees = list);
  }

  Future<void> _select(String? code) async {
    if (code == null) return;
    final name = await _repo.getName(code);
    final bound = await _repo.hasDevice(code);
    if (!mounted || name == null) return;
    setState(() {
      _code = code;
      _codeCtrl.text = code;
      _nameCtrl.text = name;
      _bound = bound;
      _nameError = null;
    });
  }

  Future<void> _save() async {
    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty) {
      setState(() => _nameError = "Tên không được để trống");
      return;
    }
    await _repo.updateName(_code!, newName);
    await _loadEmployees();
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    setState(() => _nameError = null);
    _snack("Đã cập nhật: $newName", Colors.green);
  }

  void _cancel() {
    FocusScope.of(context).unfocus();
    setState(() {
      _code = null;
      _nameError = null;
    });
  }

  Future<void> _resetPassword() async {
    final pass = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _PasswordDialog(),
    );
    if (pass == null || !mounted) return;
    await _repo.setPassword(_code!, pass);
    if (!mounted) return;
    setState(() => _bound = false);
    _snack("Đã đặt lại mật khẩu (máy cũ bị hủy liên kết)", Colors.green);
  }

  Future<void> _unbind() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.link_off, color: Colors.deepOrange, size: 44),
        title: const Text("Hủy liên kết máy"),
        content: Text(
          "Hủy liên kết điện thoại của ${_nameCtrl.text.trim()}?\n"
              "Nhân viên phải kích hoạt lại bằng mật khẩu.",
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Xác nhận"),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _repo.unbindDevice(_code!);
    if (!mounted) return;
    setState(() => _bound = false);
    _snack("Đã hủy liên kết máy", Colors.green);
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

  @override
  void dispose() {
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                Icon(
                  _bound ? Icons.phone_android : Icons.phonelink_erase,
                  color: _bound ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 10),
                Text(
                  _bound ? "Đã liên kết điện thoại" : "Chưa liên kết điện thoại",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _bound ? Colors.green.shade700 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _resetPassword,
              icon: const Icon(Icons.lock_reset),
              label: const Text("Đặt lại mật khẩu"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _bound ? _unbind : null,
              icon: const Icon(Icons.link_off),
              label: const Text("Hủy liên kết máy"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
          if (_employees.isEmpty)
            const ScanPlaceholder(
              icon: Icons.people_outline,
              text: "Chưa có nhân viên nào",
            )
          else ...[
            EmployeePicker(
              employees: _employees,
              value: _code,
              onChanged: _select,
            ),
            const SizedBox(height: 16),
            if (_code == null)
              const ScanPlaceholder(
                icon: Icons.edit,
                text: "Chọn nhân viên ở trên\nđể chỉnh sửa thông tin",
              )
            else
              _buildForm(),
          ],
        ],
      ),
    );
  }
}

/// Hộp thoại nhập mật khẩu mới. Trả về mật khẩu khi Xác nhận, null khi Hủy
class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _ctrl = TextEditingController();
  String? _error;
  bool _hide = true;

  void _confirm() {
    final pass = _ctrl.text;
    if (pass.length < kMinPasswordLength) {
      setState(() => _error = "Mật khẩu tối thiểu $kMinPasswordLength ký tự");
      return;
    }
    Navigator.pop(context, pass);
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
      icon: Icon(Icons.lock_reset, color: Colors.indigo.shade600, size: 44),
      title: const Text("Đặt lại mật khẩu"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Máy đã liên kết của nhân viên sẽ bị hủy,\nnhân viên phải kích hoạt lại.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            obscureText: _hide,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _confirm(),
            decoration: InputDecoration(
              labelText: "Mật khẩu mới",
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_hide ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _hide = !_hide),
              ),
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