import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'member_store.dart';

/// Email and password session against the API. The token is memory only,
/// so a restart signs the member out.
class SessionController extends ChangeNotifier {
  SessionController(this.api, this.store) {
    api.onUnauthorized = _drop;
  }

  final ApiClient api;
  final MemberStore store;

  /// Token held, terms accepted, and the member's data loaded.
  bool isSignedIn = false;

  /// Token held but the Terms and Privacy Policy are not accepted yet.
  bool needsTerms = false;

  static bool isValidEmail(String email) {
    final e = email.trim();
    final at = e.indexOf('@');
    return at > 0 && e.indexOf('.', at) > at + 1 && !e.endsWith('.');
  }

  /// Throws [ApiException] with a message the screen can show.
  Future<void> login(String email, String password) async {
    final r = await api.post('/auth/login', {
      'email': email.trim(),
      'password': password,
    }) as Map;
    api.token = r['token'] as String;
    if (r['termsAccepted'] == true) {
      await _enter();
    } else {
      needsTerms = true;
      notifyListeners();
    }
  }

  /// Throws [ApiException].
  Future<void> acceptTerms() async {
    await api.post('/auth/accept-terms');
    await _enter();
  }

  Future<void> _enter() async {
    try {
      await store.load();
    } on ApiException {
      api.token = null;
      needsTerms = false;
      notifyListeners();
      rethrow;
    }
    needsTerms = false;
    isSignedIn = true;
    notifyListeners();
  }

  /// Revokes the session on the server without waiting for it, so sign out
  /// works offline too. Attendance and the plan stay on the server.
  void signOut() {
    if (api.token != null) {
      unawaited(api.post('/auth/logout').then((_) {}, onError: (_) {}));
    }
    _drop();
  }

  void _drop() {
    api.token = null;
    isSignedIn = false;
    needsTerms = false;
    store.clear();
    notifyListeners();
  }
}
