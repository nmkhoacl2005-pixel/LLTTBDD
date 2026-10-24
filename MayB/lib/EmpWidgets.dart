import 'package:flutter/material.dart';
import 'ActivateScreen.dart';
import 'AuthStorage.dart';

String two(int n) => n.toString().padLeft(2, '0');
String formatTime(DateTime t) => "${two(t.hour)}:${two(t.minute)}:${two(t.second)}";
String formatDate(DateTime t) => "${two(t.day)}/${two(t.month)}/${t.year}";
String formatSec(int s) => "${two(s ~/ 3600)}:${two((s % 3600) ~/ 60)}:${two(s % 60)}";

/// Chữ cái đầu của tên (dùng cho avatar)
String initialOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  final last = parts.isEmpty ? '' : parts.last;
  return last.isEmpty ? '?' : last[0].toUpperCase();
}

/// Xóa đăng nhập rồi về màn Kích hoạt
Future<void> goActivate(BuildContext context, String? msg) async {
  await AuthStorage.clear();
  if (!context.mounted) return;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => ActivateScreen(message: msg)),
    (_) => false,
  );
}

/// Khung placeholder (chưa có dữ liệu / lỗi...)
class InfoPlaceholder extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const InfoPlaceholder({super.key, required this.icon, required this.text, this.color});

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
          Icon(icon, size: 72, color: color ?? Colors.indigo.shade200),
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
