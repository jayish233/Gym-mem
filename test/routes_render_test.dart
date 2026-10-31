import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'test_app.dart';

void main() {
  for (final route in [
    '/home',
    '/history',
    '/scan',
    '/plan',
    '/profile',
    '/privacy',
    '/terms',
  ]) {
    testWidgets('$route renders at 390 × 844 without overflow', (tester) async {
      await pumpApp(tester, signedIn: true);
      GoRouter.of(tester.element(find.byType(Navigator).first)).go(route);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('sign in is two panes at 1024 wide', (tester) async {
    await pumpApp(tester, size: const Size(1024, 768));
    final headline = tester.getTopLeft(
      find.text('See who is drifting before they leave.'),
    );
    final title = tester.getTopLeft(find.text('Sign in'));
    expect(title.dx, greaterThan(headline.dx + 400));
    expect(tester.takeException(), isNull);
  });

  testWidgets('scan success adds today once and Home shows 13', (tester) async {
    final (_, store) = await pumpApp(tester, signedIn: true);
    await tester.tap(find.text('Scan to check in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Allow camera'));
    await tester.pump();
    await tester.tap(find.text('Preview: success'));
    await tester.pump();
    expect(find.text('You are checked in'), findsOneWidget);
    expect(find.text('13-day streak'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('13'), findsOneWidget);
    expect(find.text('Checked in today'), findsOneWidget);
    expect(store.checkedInToday, isTrue);
  });
}
