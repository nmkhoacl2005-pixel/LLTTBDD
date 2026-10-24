import 'package:flutter/material.dart';
import 'package:mayb/HomeScreen.dart';
import 'AuthStorage.dart';
import 'BleClient.dart';

class ActivateScreen extends StatefulWidget {
  final String? message; // ví dụ: thông báo bị hủy liên kết
  const ActivateScreen({Key? key, this.message}) : super(key: key);

  @override
  State<ActivateScreen> createState() => _ActivateScreenState();
}

class _ActivateScreenState extends State<ActivateScreen> {
  final _codeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _busy = false;
  bool _hide = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _error = widget.message;
  }

  Future<void> _activate() async {
    final code = _codeCtrl.text.trim();
    final pass = _passCtrl.text;
    if (code.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Vui lòng nhập mã nhân viên và mật khẩu');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    final r = await BleClient.instance.activate(code, pass);
    if (!mounted) return;

    if (r.ok && r.token != null) {
      await AuthStorage.save(code, r.token!, r.name ?? code);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() {
        _busy = false;
        _error = r.error ?? 'Kích hoạt thất bại';
      });
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kích hoạt máy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.phonelink_lock, size: 56, color: Colors.indigo.shade400),
                const SizedBox(height: 12),
                const Text(
                  'Nhập mã nhân viên và mật khẩu do quản lý cấp.',
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.4),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  enabled: !_busy,
                  decoration: InputDecoration(
                    labelText: 'Mã nhân viên',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtrl,
                  obscureText: _hide,
                  enabled: !_busy,
                  onSubmitted: (_) => _activate(),
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_hide ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _hide = !_hide),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _busy ? null : _activate,
                  icon: _busy
                      ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.link),
                  label: Text(_busy ? 'Đang tìm máy trạm...' : 'Đang kích hoạt...'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}