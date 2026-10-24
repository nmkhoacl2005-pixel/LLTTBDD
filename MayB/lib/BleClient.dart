import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'AuthStorage.dart';
import 'Protocol.dart';

class BleException implements Exception {
  final String message;
  BleException(this.message);
}

class BleClient {
  BleClient._();
  static final BleClient instance = BleClient._();

  final Guid _svc = Guid(kServiceUuid);
  final Guid _chr = Guid(kCharUuid);
  bool _busy = false;

  Future<BleResult> activate(String code, String password) async {
    final id = await AuthStorage.deviceId();
    try {
      final res = await _post(
          '/api/device/activate', {'code': code, 'password': password, 'deviceId': id});
      if (res.statusCode != 200) return BleResult.fail(_apiError(res));
      final m = jsonDecode(utf8.decode(res.bodyBytes));
      return BleResult(ok: true, token: m['token']?.toString(), name: m['name']?.toString());
    } on TimeoutException {
      return BleResult.fail('Hết thời gian chờ server phản hồi');
    } catch (_) {
      return BleResult.fail('Không kết nối được server');
    }
  }

  Future<BleResult> checkIn() async {
    final code = await AuthStorage.code();
    final token = await AuthStorage.token();
    if (code == null || token == null) return BleResult.fail('Chưa kích hoạt máy');
    final id = await AuthStorage.deviceId();
    return _single(buildCheckIn(code, token, id));
  }

  /// Lấy báo cáo 1 tháng: nhiều gói yêu cầu trên CÙNG 1 kết nối
  Future<ReportResult> monthReport(int year, int month) async {
    final code = await AuthStorage.code();
    final token = await AuthStorage.token();
    if (code == null || token == null) return const ReportResult.fail('Chưa kích hoạt máy');
    final id = await AuthStorage.deviceId();
    try {
      final res = await _post('/api/device/report',
          {'code': code, 'token': token, 'deviceId': id, 'year': year, 'month': month});
      if (res.statusCode != 200) return ReportResult.fail(_apiError(res));
      final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
      return ReportResult.ok(list.map((e) {
        final ci = DateTime.parse(e['checkIn']);
        final co = e['checkOut'] == null ? null : DateTime.parse(e['checkOut']);
        return DayRecord(
          day: DateTime.parse(e['date']).day,
          inSec: _sec(ci),
          outSec: co == null ? null : _sec(co),
          late: e['isLate'] == true,
          early: e['isEarlyLeave'] == true,
        );
      }).toList());
    } on TimeoutException {
      return ReportResult.fail('Hết thời gian chờ server phản hồi');
    } catch (_) {
      return ReportResult.fail('Không kết nối được server');
    }
  }

  Future<http.Response> _post(String path, Map<String, dynamic> data) => http
      .post(Uri.parse('$kApiBaseUrl$path'),
      headers: {'Content-Type': 'application/json'}, body: jsonEncode(data))
      .timeout(const Duration(seconds: 10));

  /// Lấy {"error": "..."} từ backend; 401 = máy bị hủy liên kết
  String _apiError(http.Response res) {
    try {
      final m = jsonDecode(utf8.decode(res.bodyBytes));
      if (m is Map && m['error'] != null) return m['error'].toString();
    } catch (_) {}
    return 'Lỗi server (${res.statusCode})';
  }

  int _sec(DateTime d) => d.hour * 3600 + d.minute * 60 + d.second;

  Future<BleResult> _single(String payload) async {
    try {
      return await _session<BleResult>((send) async => parseResponse(await send(payload)));
    } on BleException catch (e) {
      return BleResult.fail(e.message);
    }
  }

  /// Trả về thông báo lỗi, hoặc null nếu sẵn sàng
  Future<String?> _prepare() async {
    final res = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse, // Android <= 11 cần để quét
    ].request();
    if (res[Permission.bluetoothConnect]?.isGranted != true ||
        res[Permission.bluetoothScan]?.isGranted != true) {
      return 'Chưa cấp quyền Bluetooth cho ứng dụng';
    }
    if (!await FlutterBluePlus.isSupported) return 'Thiết bị không hỗ trợ Bluetooth LE';

    final state = await FlutterBluePlus.adapterState.first;
    if (state != BluetoothAdapterState.on) {
      try {
        await FlutterBluePlus.turnOn();
        await FlutterBluePlus.adapterState
            .where((s) => s == BluetoothAdapterState.on)
            .first
            .timeout(const Duration(seconds: 8));
      } catch (_) {
        return 'Bluetooth đang tắt, hãy bật Bluetooth rồi thử lại';
      }
    }
    return null;
  }

  Future<BluetoothDevice?> _scan() async {
    final found = Completer<BluetoothDevice?>();
    final sub = FlutterBluePlus.scanResults.listen((list) {
      if (list.isNotEmpty && !found.isCompleted) found.complete(list.first.device);
    });
    try {
      FlutterBluePlus.startScan(
        withServices: [_svc],
        timeout: const Duration(seconds: 10),
      );
      return await found.future
          .timeout(const Duration(seconds: 11), onTimeout: () => null);
    } finally {
      await sub.cancel();
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {}
    }
  }

  /// Quét → kết nối → subscribe notify → chạy [body] (gọi send() nhiều lần được) → ngắt.
  /// Mỗi send() = ghi 1 gói rồi chờ đúng 1 gói notify trả lời.
  /// Kết nối có retry, chờ 600 ms rồi mới discover (tránh bị rớt giữa chừng)
  Future<List<BluetoothService>> _connectAndDiscover(BluetoothDevice d) async {
    Object? last;
    for (var i = 0; i < 3; i++) {
      try {
        await d.connect(timeout: const Duration(seconds: 10), mtu: null);
        await Future.delayed(const Duration(milliseconds: 600));
        final services = await d.discoverServices();
        try {
          await d.requestMtu(247);
        } catch (_) {}
        return services;
      } catch (e) {
        last = e;
        try {
          await d.disconnect();
        } catch (_) {}
        await Future.delayed(const Duration(milliseconds: 800));
      }
    }
    throw BleException('Mất kết nối với máy trạm, hãy thử lại ($last)');
  }

  Future<T> _session<T>(
      Future<T> Function(Future<String> Function(String payload) send) body) async {
    if (_busy) throw BleException('Đang xử lý, vui lòng đợi');
    _busy = true;
    BluetoothDevice? device;
    StreamSubscription<List<int>>? sub;
    try {
      final err = await _prepare();
      if (err != null) throw BleException(err);

      device = await _scan();
      if (device == null) {
        throw BleException('Không tìm thấy máy trạm. Hãy lại gần máy trạm và thử lại');
      }

      final services = await _connectAndDiscover(device);
      BluetoothCharacteristic? found;
      for (final s in services) {
        if (s.uuid == _svc) {
          for (final c in s.characteristics) {
            if (c.uuid == _chr) found = c;
          }
        }
      }
      if (found == null) throw BleException('Máy trạm không đúng giao thức');
      final ch = found;

      // Ghép nhiều gói notify thành 1 phản hồi: parse JSON được = đã đủ
      final bytes = <int>[];
      Completer<String>? pending;
      sub = ch.onValueReceived.listen((v) {
        final p = pending;
        if (p == null || p.isCompleted) return;
        bytes.addAll(v);
        final s = utf8.decode(bytes, allowMalformed: true);
        try {
          jsonDecode(s);
          p.complete(s);
        } catch (_) {
          // chưa đủ, chờ thêm đoạn tiếp theo
        }
      });
      await ch.setNotifyValue(true); // subscribe TRƯỚC khi ghi

      Future<String> send(String payload) async {
        bytes.clear();
        final c = Completer<String>();
        pending = c;
        await ch.write(utf8.encode(payload));
        return c.future.timeout(const Duration(seconds: 5));
      }

      return await body(send);
    } on BleException {
      rethrow;
    } on TimeoutException {
      throw BleException('Hết thời gian chờ máy trạm phản hồi');
    } catch (e) {
      throw BleException('Lỗi Bluetooth: $e');
    } finally {
      await sub?.cancel();
      try {
        await device?.disconnect();
      } catch (_) {}
      // Cho máy trạm thời gian quảng bá lại trước phiên kế tiếp
      await Future.delayed(const Duration(milliseconds: 700));
      _busy = false;
    }
  }
}