import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AttendanceRecord {
  final String code;
  final String name;
  final DateTime time;
  final bool isCheckIn; // true = quét vào, false = quét ra

  const AttendanceRecord({
    required this.code,
    required this.name,
    required this.time,
    required this.isCheckIn,
  });
}

/// Kết quả của 1 lượt quét chấm công
class ScanResult {
  final AttendanceRecord record;
  final bool alreadyDone; // true = hôm nay đã quét RA rồi, lượt này không được ghi

  const ScanResult(this.record, {this.alreadyDone = false});
}

/// Tóm tắt 1 ngày công của 1 nhân viên
class DaySummary {
  final DateTime date;
  final DateTime checkIn;
  final DateTime? checkOut; // null = chưa quét ra

  const DaySummary({
    required this.date,
    required this.checkIn,
    required this.checkOut,
  });
}

/// Lưu dữ liệu bằng SQLite (file attendance.db trong máy).
/// Các bảng: employees, attendance, settings.
class EmployeeRepository {
  EmployeeRepository._();
  static final EmployeeRepository instance = EmployeeRepository._();

  // Dữ liệu mẫu, chỉ nạp 1 lần khi database được tạo lần đầu
  static const Map<String, String> _seed = {
    "2380601068": "Nguyễn Minh Khoa",
    "2380602431": "Nguyễn Phạm Tuân",
    "2380600564": "Đặng Thị Thái Hà",
    "2380600226": "Triệu Thị Mai Chi",
  };

  Future<Database>? _dbFuture;
  Future<Database> get _database => _dbFuture ??= _open();

  /// Gọi 1 lần trong main() để mở database trước khi chạy app
  Future<void> init() async {
    await _database;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      join(dir, 'attendance.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE employees('
              'code TEXT PRIMARY KEY, '
              'name TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE attendance('
              'id INTEGER PRIMARY KEY AUTOINCREMENT, '
              'code TEXT NOT NULL, '
              'name TEXT NOT NULL, '
              'time INTEGER NOT NULL, '
              'is_check_in INTEGER NOT NULL)',
        );
        await db.execute(
          'CREATE INDEX idx_attendance_code_time ON attendance(code, time)',
        );
        await db.execute(
          'CREATE TABLE settings('
              'key TEXT PRIMARY KEY, '
              'value TEXT NOT NULL)',
        );

        final batch = db.batch();
        _seed.forEach((code, name) {
          batch.insert('employees', {'code': code, 'name': name});
        });
        await batch.commit(noResult: true);
      },
    );
  }

  // ---------------------------------------------------------------- Nhân viên

  Future<int> count() async {
    final db = await _database;
    final r = await db.rawQuery('SELECT COUNT(*) FROM employees');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<List<MapEntry<String, String>>> employees() async {
    final db = await _database;
    final rows = await db.query('employees', orderBy: 'rowid');
    return rows
        .map((r) => MapEntry(r['code'] as String, r['name'] as String))
        .toList();
  }

  Future<String?> getName(String code) async {
    final db = await _database;
    final rows = await db.query(
      'employees',
      columns: ['name'],
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['name'] as String;
  }

  Future<void> updateName(String code, String newName) async {
    final db = await _database;
    await db.update(
      'employees',
      {'name': newName},
      where: 'code = ?',
      whereArgs: [code],
    );
  }

  Future<bool> delete(String code) async {
    final db = await _database;
    final n = await db.delete(
      'employees',
      where: 'code = ?',
      whereArgs: [code],
    );
    return n > 0;
  }

  /// Thêm nhân viên mới. Trả về false nếu mã đã tồn tại.
  Future<bool> addEmployee(String code, String name) async {
    final db = await _database;
    final id = await db.insert(
      'employees',
      {'code': code, 'name': name},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return id > 0;
  }

  // ---------------------------------------------------------------- Chấm công

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static AttendanceRecord _fromRow(Map<String, Object?> r) => AttendanceRecord(
    code: r['code'] as String,
    name: r['name'] as String,
    time: DateTime.fromMillisecondsSinceEpoch(r['time'] as int),
    isCheckIn: (r['is_check_in'] as int) == 1,
  );

  /// Lượt quét gần nhất (mới nhất trước)
  Future<List<AttendanceRecord>> history({int limit = 50}) async {
    final db = await _database;
    final rows = await db.query(
      'attendance',
      orderBy: 'time DESC',
      limit: limit,
    );
    return rows.map(_fromRow).toList();
  }

  /// Ghi 1 lượt quét. Lần quét đầu tiên trong ngày = VÀO, lần thứ hai = RA.
  /// Đã quét RA trong ngày thì không ghi thêm (alreadyDone = true).
  /// Quét trùng trong vòng 60 giây thì bỏ qua (trả về lượt quét trước đó).
  Future<ScanResult> addScan(
      String code, String name, DateTime time) async {
    final db = await _database;
    final rows = await db.query(
      'attendance',
      where: 'code = ?',
      whereArgs: [code],
      orderBy: 'time DESC',
      limit: 1,
    );
    final last = rows.isEmpty ? null : _fromRow(rows.first);

    if (last != null && time.difference(last.time).inSeconds < 60) {
      return ScanResult(last);
    }

    // Hôm nay đã RA rồi -> không cho chấm công thêm
    if (last != null && _sameDay(last.time, time) && !last.isCheckIn) {
      return ScanResult(last, alreadyDone: true);
    }

    final hasScanToday = last != null && _sameDay(last.time, time);
    final record = AttendanceRecord(
      code: code,
      name: name,
      time: time,
      isCheckIn: !hasScanToday,
    );
    await db.insert('attendance', {
      'code': code,
      'name': name,
      'time': time.millisecondsSinceEpoch,
      'is_check_in': record.isCheckIn ? 1 : 0,
    });
    return ScanResult(record);
  }

  /// Chi tiết chấm công của 1 nhân viên trong 1 tháng (theo từng ngày).
  /// Giờ vào = lần quét đầu tiên, giờ ra = lần quét cuối cùng trong ngày.
  Future<List<DaySummary>> monthSummary(
      String code, int year, int month) async {
    final db = await _database;
    final start = DateTime(year, month).millisecondsSinceEpoch;
    final end = DateTime(year, month + 1).millisecondsSinceEpoch;
    final rows = await db.query(
      'attendance',
      columns: ['time'],
      where: 'code = ? AND time >= ? AND time < ?',
      whereArgs: [code, start, end],
      orderBy: 'time ASC',
    );

    final byDay = <int, List<DateTime>>{};
    for (final r in rows) {
      final t = DateTime.fromMillisecondsSinceEpoch(r['time'] as int);
      byDay.putIfAbsent(t.day, () => []).add(t);
    }

    final days = byDay.keys.toList()..sort();
    return days.map((d) {
      final times = byDay[d]!;
      return DaySummary(
        date: DateTime(year, month, d),
        checkIn: times.first,
        checkOut: times.length > 1 ? times.last : null,
      );
    }).toList();
  }

  // ---------------------------------------------------------------- Cài đặt

  Future<String?> getSetting(String key) async {
    final db = await _database;
    final rows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await _database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}