import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';

// Hằng số giao thức — phải GIỐNG HỆT máy trạm
const String kServiceUuid = '7e1a0001-5f3b-4c1e-9b7a-2d4f6a8c9e10';
const String kCharUuid = '7e1a0002-5f3b-4c1e-9b7a-2d4f6a8c9e10';
const String kStationName = 'CC-Tram';


String get kApiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';

// Lỗi từ máy trạm cần xử lý riêng
const String kErrUnlinked = 'Máy chưa được liên kết';

/// Cache báo cáo tháng (key "năm-tháng"), xóa khi đăng xuất
final Map<String, List<DayRecord>> reportCache = {};

/// Gói kích hoạt (lần đầu)
String buildActivate(String code, String password, String deviceId) =>
    jsonEncode({'t': 'A', 'c': code, 'p': password, 'd': deviceId});

/// Gói chấm công
String buildCheckIn(String code, String token, String deviceId) =>
    jsonEncode({'t': 'C', 'c': code, 'k': token, 'd': deviceId});

/// Gói xin báo cáo tháng (phân trang: máy trạm trả tối đa 8 ngày / gói)
String buildReport(String code, String token, String deviceId, int year,
    int month, int offset) =>
    jsonEncode({
      't': 'R',
      'c': code,
      'k': token,
      'd': deviceId,
      'y': year,
      'm': month,
      'o': offset,
    });

class BleResult {
  final bool ok;
  final String? error;
  final String? token;
  final String? name;
  final bool isCheckIn; // true = vào, false = ra
  final bool done; // hôm nay đã ra rồi, lượt này không được ghi
  final String? status;
  final DateTime? time;

  const BleResult({
    required this.ok,
    this.error,
    this.token,
    this.name,
    this.isCheckIn = false,
    this.done = false,
    this.status,
    this.time,
  });

  factory BleResult.fail(String error) => BleResult(ok: false, error: error);
}

BleResult parseResponse(String raw) {
  try {
    final m = jsonDecode(raw);
    if (m is! Map) return BleResult.fail('Phản hồi không hợp lệ');
    if (m['ok'] != 1) {
      return BleResult.fail((m['e'] ?? 'Lỗi không xác định').toString());
    }
    final tm = m['tm'];
    return BleResult(
      ok: true,
      token: m['tk']?.toString(),
      name: m['n']?.toString(),
      isCheckIn: m['in'] == 1,
      done: m['done'] == 1,
      status: m['s']?.toString(),
      time: tm is num ? DateTime.fromMillisecondsSinceEpoch(tm.toInt()) : null,
    );
  } catch (_) {
    return BleResult.fail('Phản hồi không hợp lệ');
  }
}

// ------------------------------------------------------------------ Báo cáo

/// 1 ngày công. Giờ tính bằng số giây từ 00:00.
class DayRecord {
  final int day;
  final int inSec;
  final int? outSec; // null = chưa quét ra
  final bool late;
  final bool early;

  const DayRecord({
    required this.day,
    required this.inSec,
    required this.outSec,
    required this.late,
    required this.early,
  });
}

class ReportPage {
  final bool ok;
  final String? error;
  final int total; // tổng số ngày công trong tháng
  final List<DayRecord> rows;

  const ReportPage.ok(this.total, this.rows)
      : ok = true,
        error = null;
  const ReportPage.fail(this.error)
      : ok = false,
        total = 0,
        rows = const [];
}

ReportPage parseReport(String raw) {
  try {
    final m = jsonDecode(raw);
    if (m is! Map) return const ReportPage.fail('Phản hồi không hợp lệ');
    if (m['ok'] != 1) {
      return ReportPage.fail((m['e'] ?? 'Lỗi không xác định').toString());
    }
    final rows = (m['d'] as List).map((e) {
      final r = e as List;
      final out = (r[2] as num).toInt();
      return DayRecord(
        day: (r[0] as num).toInt(),
        inSec: (r[1] as num).toInt(),
        outSec: out < 0 ? null : out,
        late: r[3] == 1,
        early: r[4] == 1,
      );
    }).toList();
    return ReportPage.ok((m['n'] as num).toInt(), rows);
  } catch (_) {
    return const ReportPage.fail('Phản hồi không hợp lệ');
  }
}

class ReportResult {
  final bool ok;
  final String? error;
  final List<DayRecord> days;

  const ReportResult.ok(this.days)
      : ok = true,
        error = null;
  const ReportResult.fail(this.error)
      : ok = false,
        days = const [];
}