import 'package:flutter/material.dart';

import 'tokens.dart';

ThemeData buildPresenceTheme() {
  final base = ThemeData(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: PresenceColors.mist,
    colorScheme: const ColorScheme.light(
      primary: PresenceColors.ink,
      onPrimary: PresenceColors.mist,
      secondary: PresenceColors.teal,
      onSecondary: PresenceColors.ink,
      surface: PresenceColors.mist,
      onSurface: PresenceColors.ink,
      error: PresenceColors.ink,
      onError: PresenceColors.mist,
    ),
    textTheme: base.textTheme.apply(
      fontFamily: PresenceType.body.fontFamily,
      bodyColor: PresenceColors.ink,
      displayColor: PresenceColors.ink,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: PresenceColors.ink,
      selectionColor: PresenceColors.tealWash,
      selectionHandleColor: PresenceColors.deepTeal,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    focusColor: PresenceColors.tealWash,
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: PresenceColors.ink,
        borderRadius: BorderRadius.circular(PresenceRadius.segment),
      ),
      textStyle: PresenceType.sans(12, color: PresenceColors.mist),
    ),
  );
}
