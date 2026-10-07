import 'package:flutter/material.dart';
import 'CommonWidgets.dart';
import 'WorkSchedule.dart';

/// Tab 5: cài đặt giờ vào / giờ ra chuẩn
class ScheduleSettingsScreen extends StatefulWidget {
  const ScheduleSettingsScreen({super.key});

  @override
  State<ScheduleSettingsScreen> createState() => _ScheduleSettingsScreenState();
}

class _ScheduleSettingsScreenState extends State<ScheduleSettingsScreen> {
  final _s = WorkSchedule.instance;

  String _fmt(TimeOfDay t) => "${two(t.hour)}:${two(t.minute)}";

  Future<void> _pick({required bool isCheckIn}) async {
    final current = isCheckIn ? _s.checkInTime : _s.checkOutTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;

    final other = isCheckIn ? _s.checkOutTime : _s.checkInTime;
    final ok = isCheckIn
        ? WorkSchedule.toMinutes(picked) < WorkSchedule.toMinutes(other)
        : WorkSchedule.toMinutes(picked) > WorkSchedule.toMinutes(other);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Giờ ra phải sau giờ vào"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      if (isCheckIn) {
        _s.checkInTime = picked;
      } else {
        _s.checkOutTime = picked;
      }
    });
    await _s.save(); // lưu vào SQLite
  }

  Widget _timeCard({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _fmt(time),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
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
          _timeCard(
            icon: Icons.login,
            color: Colors.green.shade700,
            title: "Giờ vào làm",
            desc: "Quét vào sau giờ này = Đi trễ",
            time: _s.checkInTime,
            onTap: () => _pick(isCheckIn: true),
          ),
          const SizedBox(height: 12),
          _timeCard(
            icon: Icons.logout,
            color: Colors.deepOrange.shade700,
            title: "Giờ tan làm",
            desc: "Quét ra trước giờ này = Về sớm",
            time: _s.checkOutTime,
            onTap: () => _pick(isCheckIn: false),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.indigo.shade400),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Mỗi ngày, lần quét đầu tiên được tính là VÀO, "
                    "các lần quét sau là RA (lấy lần quét cuối cùng).\n"
                    "Quét lại cùng 1 mã trong vòng 60 giây sẽ bị bỏ qua.",
                    style: TextStyle(
                        height: 1.4, color: Colors.indigo.shade900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
