import 'dart:async';
import 'dart:convert';

import 'package:ble_peripheral/ble_peripheral.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import 'CheckInHandler.dart';

/// Máy trạm BLE (Peripheral): phát tín hiệu, nhận gói ghi từ điện thoại nhân viên
/// rồi trả kết quả lại qua notify. Dùng [start] để mở, [stop] để đóng.
class BluetoothService {
  BluetoothService._();
  static final BluetoothService instance = BluetoothService._();

  // Hai UUID này app nhân viên phải dùng y hệt (sau này đưa vào Protocol.dart)
  static const String serviceUuid = "7e1a0001-5f3b-4c1e-9b7a-2d4f6a8c9e10";
  static const String charUuid = "7e1a0002-5f3b-4c1e-9b7a-2d4f6a8c9e10";

  bool _starting = false;
  bool _initialized = false;
  final Set<String> _devices = {};

  /// true = máy trạm đang mở (đang phát tín hiệu)
  final ValueNotifier<bool> running = ValueNotifier<bool>(false);
  final ValueNotifier<String> status =
  ValueNotifier<String>("Máy trạm đang đóng");

  /// true = đang có ít nhất 1 điện thoại nhân viên kết nối
  final ValueNotifier<bool> connected = ValueNotifier<bool>(false);

  Future<bool> _askPermissions() async {
    final r = await [
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();
    return r.values.every((s) => s.isGranted);
  }

  /// Xử lý 1 gói nhận được rồi gửi kết quả về đúng điện thoại đó
  Future<void> _handle(String deviceId, String raw) async {
    final reply = await CheckInHandler.instance.handle(raw);
    final bytes = utf8.encode(reply);
    const chunk = 20;
    try {
      for (var i = 0; i < bytes.length; i += chunk) {
        final end = (i + chunk < bytes.length) ? i + chunk : bytes.length;
        await BlePeripheral.updateCharacteristic(
          characteristicId: charUuid,
          value: Uint8List.fromList(bytes.sublist(i, end)),
          deviceId: deviceId,
        );
        await Future.delayed(const Duration(milliseconds: 25));
      }
    } catch (e) {
      debugPrint("Lỗi gửi kết quả: $e");
    }
  }

  Future<void> start() async {
    if (running.value || _starting) return;
    _starting = true;
    status.value = "Đang mở máy trạm...";

    try {
      if (!await _askPermissions()) {
        status.value = "Chưa cấp quyền Bluetooth";
        return;
      }

      if (!_initialized) {
        await BlePeripheral.initialize();

        BlePeripheral.setAdvertisingStatusUpdateCallback((advertising, error) {
          if (error != null) {
            running.value = false;
            status.value = "Lỗi phát tín hiệu: $error";
          } else if (advertising) {
            running.value = true;
            status.value = "Máy trạm đang mở - chờ nhân viên";
          } else {
            running.value = false;
            status.value = "Máy trạm đang đóng";
          }
        });

        BlePeripheral.setConnectionStateChangeCallback((deviceId, isConnected) {
          if (isConnected) {
            _devices.add(deviceId);
          } else {
            _devices.remove(deviceId);
            _restartAdvertising();
          }
          connected.value = _devices.isNotEmpty;
        });

        BlePeripheral.setWriteRequestCallback(
                (deviceId, characteristicId, offset, value) {
              if (value != null && value.isNotEmpty) {
                _handle(deviceId, utf8.decode(value, allowMalformed: true).trim());
              }
              return null;
            });

        await BlePeripheral.addService(
          BleService(
            uuid: serviceUuid,
            primary: true,
            characteristics: [
              BleCharacteristic(
                uuid: charUuid,
                properties: [
                  CharacteristicProperties.write.index,
                  CharacteristicProperties.notify.index,
                ],
                value: null,
                permissions: [AttributePermissions.writeable.index],
              ),
            ],
          ),
        );
        _initialized = true;
      }

      try {
        await BlePeripheral.stopAdvertising();
      } catch (_) {}
      // Tên ngắn để không vượt giới hạn 31 byte của gói quảng bá
      await BlePeripheral.startAdvertising(
        services: [serviceUuid],
        localName: "CC-Tram",
      );
      running.value = true;
      status.value = "Máy trạm đang mở - chờ nhân viên";
    } catch (e) {
      running.value = false;
      status.value = "Lỗi mở máy trạm: $e";
    } finally {
      _starting = false;
    }
  }

  Future<void> stop() async {
    try {
      await BlePeripheral.stopAdvertising();
    } catch (_) {}
    _devices.clear();
    connected.value = false;
    running.value = false;
    status.value = "Máy trạm đang đóng";
  }

  Future<void> _restartAdvertising() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!running.value) return; // máy trạm đã đóng thì thôi
    try {
      await BlePeripheral.stopAdvertising();
    } catch (_) {}
    try {
      await BlePeripheral.startAdvertising(
        services: [serviceUuid],
        localName: "CC-Tram",
      );
    } catch (e) {
      debugPrint("Lỗi quảng bá lại: $e");
    }
  }
}