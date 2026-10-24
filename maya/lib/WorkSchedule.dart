import 'package:flutter/material.dart';
import 'EmployeeRepository.dart';

class StatusInfo {
  final String label;
  final MaterialColor color;
  const StatusInfo(this.label, this.color);
}

/// Giờ làm việc chuẩn dùng chung cho toàn app.
/// - Quét vào SAU [checkInTime]  -> Đi trễ
/// - Quét ra TRƯỚC [checkOutTime] -> Về sớm
class WorkSchedule {
  WorkSchedule._();
  static final WorkSchedule instance = WorkSchedule._();

  TimeOfDay checkInTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay checkOutTime = const TimeOfDay(hour: 17, minute: 0);

  static int toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;
  static int _minutesOf(DateTime d) => d.hour * 60 + d.minute;

  /// Nạp giờ làm đã lưu trong SQLite (gọi 1 lần trong main)
  Future<void> load() async {
    try {
      final j = await EmployeeRepository.instance.getSchedule();
      final inMin = j['checkInMinutes'] as int;
      final outMin = j['checkOutMinutes'] as int;
      checkInTime = TimeOfDay(hour: inMin ~/ 60, minute: inMin % 60);
      checkOutTime = TimeOfDay(hour: outMin ~/ 60, minute: outMin % 60);
    } catch (_) {
      // backend chưa mở thì dùng giờ mặc định
    }
  }

  Future<void> save() => EmployeeRepository.instance
      .setSchedule(toMinutes(checkInTime), toMinutes(checkOutTime));

  bool isLate(DateTime t) => _minutesOf(t) > toMinutes(checkInTime);
  bool isEarlyLeave(DateTime t) => _minutesOf(t) < toMinutes(checkOutTime);

  StatusInfo inStatus(DateTime t) => isLate(t)
      ? const StatusInfo('Đi trễ', Colors.orange)
      : const StatusInfo('Đúng giờ', Colors.green);

  StatusInfo outStatus(DateTime t) => isEarlyLeave(t)
      ? const StatusInfo('Về sớm', Colors.deepOrange)
      : const StatusInfo('Ra đúng giờ', Colors.green);
}
