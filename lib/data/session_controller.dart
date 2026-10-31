import 'package:flutter/foundation.dart';

/// Fake OTP session. Nothing is checked against a server.
class SessionController extends ChangeNotifier {
  static const _delay = Duration(milliseconds: 400);

  bool isSignedIn = false;
  String? pendingEmail;

  static bool isValidEmail(String email) {
    final e = email.trim();
    final at = e.indexOf('@');
    return at > 0 && e.indexOf('.', at) > at + 1 && !e.endsWith('.');
  }

  Future<void> sendCode(String email) async {
    await Future<void>.delayed(_delay);
    pendingEmail = email.trim();
    notifyListeners();
  }

  /// Accepts any 6 digits.
  Future<bool> verify(String code) async {
    await Future<void>.delayed(_delay);
    if (!RegExp(r'^\d{6}$').hasMatch(code)) return false;
    isSignedIn = true;
    notifyListeners();
    return true;
  }

  void signOut() {
    isSignedIn = false;
    pendingEmail = null;
    notifyListeners();
  }
}
