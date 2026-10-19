import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'failure.dart';

class ApiClient {
  final http.Client _client;
  final Uri? baseUrl;
  final Duration timeouts;

  ApiClient({
    http.Client? client,
    String? baseUrl,
    this.timeouts = const Duration(seconds: 10),
  })  : _client = client ?? http.Client(),
        baseUrl = baseUrl == null ? null : Uri.parse(baseUrl);

  static const Map<String, String> _headers = {
    'content-type': 'application/json; charset=utf-8',
  };

  Uri _resolve(String path) {
    final base = baseUrl;
    if (base == null) {
      return Uri.parse(path);
    }
    return base.resolve(path);
  }

  Future<dynamic> get(String path) {
    return _send(() => _client.get(_resolve(path), headers: _headers));
  }

  Future<dynamic> post(String path, {Object? body}) {
    return _send(
      () => _client.post(
        _resolve(path),
        headers: _headers,
        body: body == null ? null : jsonEncode(body),
      ),
    );
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request().timeout(timeouts);
    } on TimeoutException {
      throw const NetworkFailure();
    } on http.ClientException {
      throw const NetworkFailure();
    }

    final dynamic decoded = _decode(response.body);
    final int status = response.statusCode;

    if (status == 404) {
      throw NotFoundFailure(_detail(decoded));
    }
    if (status == 409) {
      throw ConflictFailure(_detail(decoded));
    }
    if (status == 422) {
      throw ValidationFailure(_fields(decoded));
    }
    if (status >= 500) {
      throw ServerFailure(status);
    }
    if (status >= 200 && status < 300) {
      return decoded;
    }
    throw UnexpectedFailure(status, _detail(decoded));
  }

  dynamic _decode(String body) {
    return jsonDecode(body);
  }

  String _detail(dynamic decoded) {
    if (decoded is Map && decoded['detail'] is String) {
      return decoded['detail'] as String;
    }
    return decoded.toString();
  }

  Map<String, String> _fields(dynamic decoded) {
    if (decoded is Map && decoded['fields'] is Map) {
      return (decoded['fields'] as Map).map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    }
    return const {};
  }
}
