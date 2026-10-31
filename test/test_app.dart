import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymapp/app/presence_app.dart';
import 'package:gymapp/data/member_store.dart';
import 'package:gymapp/data/mock/mock_clock.dart';
import 'package:gymapp/data/session_controller.dart';

/// Saturday 31 Oct 2026, 6:42 PM.
final testClock = MockClock(DateTime(2026, 10, 31, 18, 42));

Future<(SessionController, MemberStore)> pumpApp(
  WidgetTester tester, {
  bool signedIn = false,
  Size size = const Size(390, 844),
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);
  final session = SessionController()..isSignedIn = signedIn;
  final store = MemberStore(testClock);
  await tester.pumpWidget(PresenceApp(session: session, store: store));
  await tester.pumpAndSettle();
  return (session, store);
}

Finder tab(String label) => find.byKey(ValueKey('tab-$label'));
