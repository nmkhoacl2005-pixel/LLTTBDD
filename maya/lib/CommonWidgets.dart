import 'package:flutter/material.dart';
import 'BluetoothService.dart';

String two(int n) => n.toString().padLeft(2, '0');
String formatTime(DateTime t) => "${two(t.hour)}:${two(t.minute)}:${two(t.second)}";
String formatDate(DateTime t) => "${two(t.day)}/${two(t.month)}/${t.year}";

/// Chữ cái đầu của tên (dùng cho avatar)
String initialOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  final last = parts.isEmpty ? '' : parts.last;
  return last.isEmpty ? '?' : last[0].toUpperCase();
}

/// Thanh trạng thái kết nối Bluetooth với Máy B
class ConnectionStatusCard extends StatelessWidget {
  const ConnectionStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final bt = BluetoothService.instance;
    return ValueListenableBuilder<bool>(
      valueListenable: bt.connected,
      builder: (context, isConnected, _) {
        final MaterialColor color = isConnected ? Colors.green : Colors.orange;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Icon(
                isConnected
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_searching,
                color: color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: bt.status,
                  builder: (_, s, __) => Text(
                    s,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: color.shade800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Khung chờ quét mã
class ScanPlaceholder extends StatelessWidget {
  final IconData icon;
  final String text;

  const ScanPlaceholder({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(icon, size: 72, color: Colors.indigo.shade200),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.4,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Thẻ báo mã QR không hợp lệ / không tồn tại
class InvalidCodeCard extends StatelessWidget {
  final String code;
  final String? hint; // dòng gợi ý thêm (tuỳ chọn)

  const InvalidCodeCard({super.key, required this.code, this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 56, color: Colors.red),
          const SizedBox(height: 12),
          const Text(
            "Mã QR không hợp lệ!",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "($code)",
            style: TextStyle(fontSize: 15, color: Colors.red.shade700),
          ),
          if (hint != null) ...[
            const SizedBox(height: 8),
            Text(
              hint!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.red.shade700),
            ),
          ],
        ],
      ),
    );
  }
}