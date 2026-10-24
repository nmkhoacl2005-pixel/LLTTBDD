import 'package:flutter/material.dart';
import 'CommonWidgets.dart';
import 'EmployeeRepository.dart';

/// Tab 7: cảnh báo khi 1 điện thoại (device ID) đang liên kết với từ 2 tài khoản trở lên
class DuplicateDeviceScreen extends StatefulWidget {
  const DuplicateDeviceScreen({super.key});

  @override
  State<DuplicateDeviceScreen> createState() => _DuplicateDeviceScreenState();
}

class _DuplicateDeviceScreenState extends State<DuplicateDeviceScreen> {
  final _repo = EmployeeRepository.instance;

  Map<String, List<MapEntry<String, String>>> _groups = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final g = await _repo.duplicateDevices();
    if (!mounted) return;
    setState(() {
      _groups = g;
      _loading = false;
    });
  }

  Future<void> _unbind(String code, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.link_off, color: Colors.deepOrange, size: 44),
        title: const Text("Hủy liên kết máy"),
        content: Text(
          "Hủy liên kết điện thoại của $name?\n"
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
    await _repo.unbindDevice(code);
    await _load();
  }

  String _shortId(String id) =>
      id.length <= 12 ? id : "${id.substring(0, 6)}...${id.substring(id.length - 4)}";

  Widget _groupCard(String deviceId, List<MapEntry<String, String>> accounts) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "${accounts.length} tài khoản dùng chung 1 máy",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "ID máy: ${_shortId(deviceId)}",
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const Divider(height: 20),
            for (final a in accounts)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.red.shade50,
                  child: Text(
                    initialOf(a.value),
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(a.value,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text("Mã: ${a.key}"),
                trailing: IconButton(
                  tooltip: "Hủy liên kết máy",
                  icon: const Icon(Icons.link_off, color: Colors.deepOrange),
                  onPressed: () => _unbind(a.key, a.value),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final entries = _groups.entries.toList();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (entries.isEmpty)
            const ScanPlaceholder(
              icon: Icons.verified_user_outlined,
              text: "Không có máy nào bị dùng chung\ncho nhiều tài khoản",
            )
          else
            for (final e in entries) ...[
              _groupCard(e.key, e.value),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}
