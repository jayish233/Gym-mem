import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

void main() {
  testWidgets('invalid email shows the error', (tester) async {
    await pumpApp(tester);
    await tester.enterText(find.byType(TextField), 'nope');
    await tester.tap(find.text('Send code'));
    await tester.pump();
    expect(find.text('Enter the email your gym has on file.'), findsOneWidget);
    expect(find.text('Enter your code'), findsNothing);
  });

  testWidgets('valid email, six digits, Verify lands on Home', (tester) async {
    await pumpApp(tester);
    await tester.enterText(find.byType(TextField), ' priya@example.com ');
    await tester.tap(find.text('Send code'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('Enter your code'), findsOneWidget);

    final verify = find.text('Verify and continue');
    await tester.enterText(find.byKey(const ValueKey('code-input')), '123');
    await tester.pump();
    await tester.tap(verify);
    await tester.pump();
    expect(find.text('Enter your code'), findsOneWidget); // still disabled

    await tester.enterText(find.byKey(const ValueKey('code-input')), '123456');
    await tester.pump();
    await tester.tap(verify);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('Good evening, Priya'), findsOneWidget);
    expect(find.text('Scan to check in'), findsOneWidget);
  });

  testWidgets('submitting fewer than six digits shows the error', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.enterText(find.byType(TextField), 'priya@example.com');
    await tester.tap(find.text('Send code'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('code-input')), '12');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('Enter all 6 digits.'), findsOneWidget);
  });
}
