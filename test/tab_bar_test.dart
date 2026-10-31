import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp/theme/tokens.dart';

import 'test_app.dart';

Color? fill(WidgetTester tester, String label) => tester
    .widget<Material>(
      find.ancestor(of: tab(label), matching: find.byType(Material)).first,
    )
    .color;

void main() {
  testWidgets('each tab navigates, marks itself active, Scan stays ink', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: true);
    const screens = {
      'History': 'Attendance',
      'Plan': 'Workout planner',
      'Profile': 'Priya Sharma',
      'Scan': 'Scan attendance',
      'Home': 'Good evening, Priya',
    };
    for (final MapEntry(key: label, value: title) in screens.entries) {
      await tester.tap(tab(label));
      await tester.pumpAndSettle();
      expect(find.text(title), findsWidgets, reason: label);
      expect(fill(tester, 'Scan'), PresenceColors.ink);
      if (label != 'Scan') {
        expect(fill(tester, label), PresenceColors.tealWash);
      }
    }
  });
}
