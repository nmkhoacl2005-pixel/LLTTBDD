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
    final repo = EmployeeRepository.instance;
    final inMin = int.tryParse(await repo.getSetting('check_in_minutes') ?? '');
    final outMin =
        int.tryParse(await repo.getSetting('check_out_minutes') ?? '');
    if (inMin != null) {
      checkInTime = TimeOfDay(hour: inMin ~/ 60, minute: inMin % 60);
    }
    if (outMin != null) {
      checkOutTime = TimeOfDay(hour: outMin ~/ 60, minute: outMin % 60);
    }
  }

  Future<void> save() async {
    final repo = EmployeeRepository.instance;
    await repo.setSetting('check_in_minutes', toMinutes(checkInTime).toString());
    await repo.setSetting(
        'check_out_minutes', toMinutes(checkOutTime).toString());
  }

  bool isLate(DateTime t) => _minutesOf(t) > toMinutes(checkInTime);
  bool isEarlyLeave(DateTime t) => _minutesOf(t) < toMinutes(checkOutTime);

  StatusInfo inStatus(DateTime t) => isLate(t)
      ? const StatusInfo('Đi trễ', Colors.orange)
      : const StatusInfo('Đúng giờ', Colors.green);

  StatusInfo outStatus(DateTime t) => isEarlyLeave(t)
      ? const StatusInfo('Về sớm', Colors.deepOrange)
      : const StatusInfo('Ra đúng giờ', Colors.green);
}
