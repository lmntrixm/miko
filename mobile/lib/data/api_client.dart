import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_errors.dart';
import 'models.dart';

/// A 4xx the caller wants to explain itself (wrong code, email taken, …).
class ApiException implements Exception {
  const ApiException(this.status, this.code, this.message);
  final int status;
  final String code;
  final String message;
  @override
  String toString() => 'ApiException($status, $code)';
}

/// Thin JSON client for the Miko API (docs/api.md). Shared status codes become the
/// app-wide exceptions that [handleApiError] already knows how to present.
class ApiClient {
  ApiClient({required this.baseUrl, required this.token, http.Client? client, this.timeout = const Duration(seconds: 15)})
      : _http = client ?? http.Client();

  final String baseUrl;
  final String? Function() token;
  final Duration timeout;
  final http.Client _http;

  Future<Map<String, dynamic>> send(String method, String path, {Object? body, Map<String, String>? query, bool auth = true}) async {
    final uri = Uri.parse('$baseUrl/v1$path').replace(queryParameters: query);
    final req = http.Request(method, uri)
      ..headers['content-type'] = 'application/json'
      ..headers['accept'] = 'application/json';
    final t = token();
    if (auth && t != null) req.headers['authorization'] = 'Bearer $t';
    if (body != null) req.body = jsonEncode(body);

    http.Response res;
    try {
      res = await http.Response.fromStream(await _http.send(req).timeout(timeout));
    } on TimeoutException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    }

    Map<String, dynamic> json = const {};
    if (res.body.isNotEmpty) {
      try {
        final d = jsonDecode(utf8.decode(res.bodyBytes));
        if (d is Map<String, dynamic>) json = d;
      } on FormatException {
        // Non-JSON (e.g. a proxy error page): fall through to status handling.
      }
    }
    if (res.statusCode < 400) return json;

    final err = json['error'] is Map ? json['error'] as Map : const {};
    final code = '${err['code'] ?? 'error'}';
    final message = '${err['message'] ?? ''}';
    switch (res.statusCode) {
      case 401 when auth && t != null:
        throw const UnauthorizedException();
      case 402:
        throw const PaywallException();
      case 426:
        throw const UpgradeRequiredException();
      case 503:
        throw const MaintenanceException();
    }
    if (res.statusCode >= 500) throw const NetworkException();
    throw ApiException(res.statusCode, code, message);
  }
}
