import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colour tokens. See CLAUDE.md section 4.2.
abstract final class PresenceColors {
  static const ink = Color(0xFF222831);
  static const graphite = Color(0xFF393E46);
  static const teal = Color(0xFF00ADB5);
  static const mist = Color(0xFFEEEEEE);
  static const deepTeal = Color(0xFF00747A);
  static const muted = Color(0xFF5A616B);
  static const paper = Color(0xFFFFFFFF);
  static const hairline = Color(0x1F222831); // ink @ 12 %
  static const inkSoft = Color(0x24222831); // ink @ 14 %
  static const tealWash = Color(0x2900ADB5); // teal @ 16 %
  static const mistOnInk75 = Color(0xBFEEEEEE); // mist @ 75 %
}

/// Spacing scale. See section 4.4.
abstract final class PresenceSpace {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s28 = 28;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s48 = 48;
}

/// Corner radii. See section 4.4.
abstract final class PresenceRadius {
  static const double segment = 9;
  static const double navItem = 10;
  static const double input = 12;
  static const double member = 14;
  static const double panel = 16;
  static const double tabBar = 20;
  static const double hero = 24;
}

/// Type styles. See section 4.3. Letter spacing is em × size.
abstract final class PresenceType {
  static TextStyle sans(
    double size, {
    double height = 1.5,
    FontWeight weight = FontWeight.w400,
    double em = 0,
    Color color = PresenceColors.ink,
  }) => GoogleFonts.geist(
    fontSize: size,
    height: height,
    fontWeight: weight,
    letterSpacing: em * size,
    color: color,
  );

  static TextStyle mono(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = PresenceColors.ink,
    double height = 1.4,
  }) => GoogleFonts.geistMono(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );

  static TextStyle get numeral =>
      sans(72, height: 0.9, weight: FontWeight.w500, em: -0.04);
  static TextStyle display(bool phone) =>
      sans(phone ? 32 : 48, height: 1.05, weight: FontWeight.w600, em: -0.03);
  static TextStyle get figure =>
      sans(38, height: 1.0, weight: FontWeight.w500, em: -0.035);
  static TextStyle get pageTitle =>
      sans(24, height: 1.1, weight: FontWeight.w600, em: -0.02);
  static TextStyle get resultTitle =>
      sans(28, height: 1.1, weight: FontWeight.w600, em: -0.025);
  static TextStyle get section =>
      sans(17, height: 1.3, weight: FontWeight.w600, em: -0.01);
  static TextStyle get body => sans(15);
  static TextStyle get bodyMuted => sans(15, color: PresenceColors.muted);
  static TextStyle get label => sans(13, height: 1.4, weight: FontWeight.w500);
  static TextStyle get caption => sans(13, color: PresenceColors.muted);
}
