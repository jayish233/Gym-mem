import 'package:flutter/material.dart';

import 'app/presence_app.dart';
import 'data/member_store.dart';
import 'data/mock/mock_clock.dart';
import 'data/session_controller.dart';

void main() {
  final clock = MockClock();
  runApp(PresenceApp(session: SessionController(), store: MemberStore(clock)));
}
