import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A failed call. [message] is one sentence the UI can show as is.
class ApiException implements Exception {
  const ApiException(this.status, this.code, this.message);

  /// 0 when the server was not reached.
  final int status;
  final String code;
  final String message;

  static const offline = ApiException(
    0,
    'offline',
    'Could not reach Presence. Check your connection and try again.',
  );

  @override
  String toString() => 'ApiException($status, $code)';
}

/// JSON over HTTP to the Presence server (server/ in this repo).
/// The session token lives only in memory.
class ApiClient {
  ApiClient(String baseUrl)
    : baseUrl = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl;

  final String baseUrl;
  String? token;

  /// Called when the server rejects the token (expired or revoked).
  void Function()? onUnauthorized;

  late final _http = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10);

  Future<dynamic> get(String path) => send('GET', path);

  Future<dynamic> post(String path, [Object? body]) => send('POST', path, body);

  Future<dynamic> put(String path, Object body) => send('PUT', path, body);

  Future<dynamic> patch(String path, Object body) => send('PATCH', path, body);

  Future<dynamic> send(String method, String path, [Object? body]) async {
    final auth = token; // read before any await so sign-out can drop it
    final HttpClientResponse res;
    final String text;
    try {
      final req = await _http.openUrl(method, Uri.parse('$baseUrl$path'));
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (auth != null) {
        req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $auth');
      }
      if (body != null) {
        req.headers.contentType = ContentType.json;
        req.add(utf8.encode(jsonEncode(body)));
      }
      // shortcut: 60 s covers a free-tier host waking from sleep; lower it
      // once the server is always on.
      res = await req.close().timeout(const Duration(seconds: 60));
      text = await res.transform(utf8.decoder).join();
    } on IOException {
      throw ApiException.offline;
    } on TimeoutException {
      throw ApiException.offline;
    }

    Object? json;
    try {
      json = text.isEmpty ? null : jsonDecode(text);
    } on FormatException {
      throw ApiException.offline; // not our server (captive portal, proxy)
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return json;
    if (res.statusCode == 401 && auth != null) onUnauthorized?.call();
    final error = json is Map ? json : const {};
    throw ApiException(
      res.statusCode,
      '${error['error'] ?? 'http_${res.statusCode}'}',
      '${error['message'] ?? 'Something went wrong. Try again.'}',
    );
  }
}
