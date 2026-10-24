import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Lỗi gọi API. [status] = null nghĩa là không kết nối được server
class ApiException implements Exception {
  final String message;
  final int? status;

  ApiException(this.message, [this.status]);

  @override
  String toString() => message;
}

/// Gọi backend. Địa chỉ lấy từ API_BASE_URL trong file ..env
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const _timeout = Duration(seconds: 8);
  static const _headers = {'Content-Type': 'application/json'};

  String get baseUrl =>
      (dotenv.env['API_BASE_URL'] ?? '').trim().replaceAll(RegExp(r'/+$'), '');

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send(() => http.get(_uri(path, query), headers: _headers));

  Future<dynamic> post(String path, [Object? body]) => _send(() => http.post(
        _uri(path),
        headers: _headers,
        body: body == null ? null : jsonEncode(body),
      ));

  Future<dynamic> put(String path, Object body) => _send(
      () => http.put(_uri(path), headers: _headers, body: jsonEncode(body)));

  Future<dynamic> delete(String path) =>
      _send(() => http.delete(_uri(path), headers: _headers));

  Future<dynamic> _send(Future<http.Response> Function() call) async {
    try {
      final res = await call().timeout(_timeout);
      final text = utf8.decode(res.bodyBytes);
      final data = text.isEmpty ? null : jsonDecode(text);
      if (res.statusCode >= 200 && res.statusCode < 300) return data;
      final msg = data is Map && data['error'] != null
          ? data['error'].toString()
          : 'Lỗi server (${res.statusCode})';
      throw ApiException(msg, res.statusCode);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('Không kết nối được server');
    } catch (_) {
      throw ApiException('Không kết nối được server');
    }
  }
}
