import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymapp/app/presence_app.dart';
import 'package:gymapp/data/member_store.dart';
import 'package:gymapp/data/mock/mock_clock.dart';
import 'package:gymapp/data/session_controller.dart';

import 'fake_api.dart';

/// Saturday 31 Oct 2026, 6:42 PM.
final testClock = MockClock(DateTime(2026, 10, 31, 18, 42));

/// Signs in through the API (terms already accepted) and loads the store.
Future<(SessionController, MemberStore, FakeApi)> signedIn() async {
  final api = FakeApi(testClock)..termsAccepted = true;
  final store = MemberStore(api, testClock);
  final session = SessionController(api, store);
  await session.login('priya.sharma@example.com', FakeApi.password);
  return (session, store, api);
}

Future<(SessionController, MemberStore, FakeApi)> pumpApp(
  WidgetTester tester, {
  bool signedIn = false,
  Size size = const Size(390, 844),
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);
  final api = FakeApi(testClock);
  final store = MemberStore(api, testClock);
  final session = SessionController(api, store);
  if (signedIn) {
    api.termsAccepted = true;
    await tester.runAsync(
      () => session.login('priya.sharma@example.com', FakeApi.password),
    );
  }
  await tester.pumpWidget(PresenceApp(session: session, store: store));
  await tester.pumpAndSettle();
  return (session, store, api);
}

Finder tab(String label) => find.byKey(ValueKey('tab-$label'));
