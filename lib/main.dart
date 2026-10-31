import 'package:flutter/material.dart';

import 'app/presence_app.dart';
import 'data/api_client.dart';
import 'data/member_store.dart';
import 'data/mock/mock_clock.dart';
import 'data/session_controller.dart';

/// Set with `flutter run --dart-define=API_URL=http://192.168.1.20:3000`.
const apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue:
      'http://10.0.2.2:3000', // the host Mac, from the Android emulator
);

void main() {
  final api = ApiClient(apiUrl);
  final store = MemberStore(api, MockClock());
  runApp(PresenceApp(session: SessionController(api, store), store: store));
}
