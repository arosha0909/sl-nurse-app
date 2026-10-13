import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'token_store.dart';

/// An error the UI can show. [fieldErrors] carries per-field messages from 422 responses.
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.status = 0,
    this.code = 'ERROR',
    this.fieldErrors = const {},
  });

  final String message;
  final int status;
  final String code;
  final Map<String, String> fieldErrors;

  bool get isNetwork => status == 0;

  /// The nurse's subscription plan doesn't include this feature (HTTP 402).
  bool get isPlanLocked => status == 402;
  bool get isUnauthorized => status == 401;

  @override
  String toString() => message;
}

/// Thin JSON client for sl-nurse-api.
///
/// - Unwraps the `{ success, data }` envelope and maps `{ error }` to [ApiException].
/// - Adds the bearer token and, on a 401, refreshes the token pair once (rotation) and
///   retries. Concurrent requests share a single refresh.
/// - Calls [onSessionExpired] when the refresh token is no longer valid.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.tokens,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 20),
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final TokenStore tokens;
  final Duration timeout;
  final http.Client _http;

  void Function()? onSessionExpired;
  Future<bool>? _refreshing;

  Uri _uri(String path, [Map<String, String>? query]) => Uri.parse(
    '$baseUrl/api/v1$path',
  ).replace(queryParameters: query == null || query.isEmpty ? null : query);

  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    bool auth = true,
  }) => _send('GET', path, query: query, auth: auth);
  Future<dynamic> post(String path, {Object? body, bool auth = true}) =>
      _send('POST', path, body: body, auth: auth);
  Future<dynamic> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);
  Future<dynamic> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);
  Future<dynamic> delete(String path) => _send('DELETE', path);

  /// Multipart upload (roster image). [fields] are sent as text parts.
  Future<dynamic> upload(
    String path, {
    required Map<String, String> fields,
    List<int>? bytes,
    String? filename,
    String? mimeType,
  }) {
    return _withAuthRetry(() async {
      final req = http.MultipartRequest('POST', _uri(path))
        ..fields.addAll(fields);
      await _authorize(req.headers);
      if (bytes != null) {
        req.files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: filename ?? 'roster.jpg',
            contentType: MediaType.parse(mimeType ?? 'image/jpeg'),
          ),
        );
      }
      final streamed = await _http
          .send(req)
          .timeout(timeout * 3); // OCR can be slow
      return http.Response.fromStream(streamed);
    });
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    bool auth = true,
  }) {
    Future<http.Response> attempt() async {
      final req = http.Request(method, _uri(path, query));
      req.headers['Accept'] = 'application/json';
      if (body != null) {
        req.headers['Content-Type'] = 'application/json';
        req.body = jsonEncode(body);
      }
      if (auth) await _authorize(req.headers);
      return http.Response.fromStream(await _http.send(req).timeout(timeout));
    }

    return auth ? _withAuthRetry(attempt) : _guard(attempt).then(_decode);
  }

  Future<void> _authorize(Map<String, String> headers) async {
    final t = await tokens.read();
    if (t != null) headers['Authorization'] = 'Bearer ${t.accessToken}';
  }

  Future<dynamic> _withAuthRetry(
    Future<http.Response> Function() attempt,
  ) async {
    var res = await _guard(attempt);
    if (res.statusCode == 401 && await _refresh()) {
      res = await _guard(attempt);
    }
    if (res.statusCode == 401) {
      await tokens.clear();
      onSessionExpired?.call();
    }
    return _decode(res);
  }

  /// One refresh at a time; parallel 401s await the same future.
  Future<bool> _refresh() {
    return _refreshing ??= () async {
      try {
        final current = await tokens.read();
        if (current == null) return false;
        final res = await _guard(
          () => _http
              .post(
                _uri('/auth/refresh'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({'refreshToken': current.refreshToken}),
              )
              .timeout(timeout),
        );
        if (res.statusCode != 200) return false;
        final data =
            (jsonDecode(res.body) as Map<String, dynamic>)['data']
                as Map<String, dynamic>;
        await tokens.write(readTokens(data['tokens'] as Map<String, dynamic>));
        return true;
      } catch (_) {
        return false;
      } finally {
        _refreshing = null;
      }
    }();
  }

  static AuthTokens readTokens(Map<String, dynamic> json) => AuthTokens(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
  );

  Future<http.Response> _guard(Future<http.Response> Function() attempt) async {
    try {
      return await attempt();
    } on TimeoutException {
      throw const ApiException(
        'The server took too long to respond. Please try again.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Can\'t reach the server. Check your connection and try again.',
      );
    }
  }

  dynamic _decode(http.Response res) {
    if (res.statusCode == 204 || res.body.isEmpty) return null;

    Map<String, dynamic> json;
    try {
      json = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        'Unexpected response from the server (${res.statusCode}).',
        status: res.statusCode,
      );
    }

    if (res.statusCode >= 200 &&
        res.statusCode < 300 &&
        json['success'] == true) {
      return json['data'];
    }

    final error = (json['error'] as Map<String, dynamic>?) ?? const {};
    final fieldErrors = <String, String>{};
    final details = error['details'];
    if (details is List) {
      for (final d in details.whereType<Map<String, dynamic>>()) {
        final path = d['path'] as String? ?? '';
        if (path.isNotEmpty) {
          fieldErrors.putIfAbsent(
            path,
            () => d['message'] as String? ?? 'Invalid value',
          );
        }
      }
    }
    throw ApiException(
      error['message'] as String? ??
          'Something went wrong (${res.statusCode}).',
      status: res.statusCode,
      code: error['code'] as String? ?? 'ERROR',
      fieldErrors: fieldErrors,
    );
  }

  void close() => _http.close();
}
