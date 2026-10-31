import 'package:flutter/material.dart';

import '../data/models/attendance_day.dart';
import '../theme/tokens.dart';

const dayStateWords = {
  DayState.present: 'attended',
  DayState.missed: 'missed',
  DayState.closed: 'gym closed',
  DayState.today: 'today',
  DayState.upcoming: 'upcoming',
  DayState.notJoined: 'before your membership',
};

/// Circular calendar day (section 4.7). [onInk] switches to the dark-panel
/// variant where mist replaces ink.
class DayCell extends StatelessWidget {
  const DayCell({
    super.key,
    required this.day,
    required this.state,
    required this.isToday,
    required this.semanticLabel,
    this.onInk = false,
    this.fontSize = 14,
  });

  final int day;
  final DayState state;
  final bool isToday;
  final String semanticLabel;
  final bool onInk;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    if (state == DayState.notJoined) {
      return const AspectRatio(aspectRatio: 1);
    }
    final base = onInk ? PresenceColors.mist : PresenceColors.ink;
    final quiet = onInk ? PresenceColors.mistOnInk75 : PresenceColors.muted;
    final (Color? fill, Color text) = switch (state) {
      DayState.present => (PresenceColors.teal, PresenceColors.ink),
      DayState.missed => (base.withValues(alpha: 0.14), base),
      DayState.today => (null, base),
      _ => (null, quiet),
    };
    final ring = isToday ? Border.all(color: base, width: 2) : null;
    Widget cell = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: ring,
      ),
      child: Text('$day', style: PresenceType.mono(fontSize, color: text)),
    );
    if (state == DayState.closed) {
      cell = CustomPaint(
        painter: DashedCircle(base.withValues(alpha: 0.5)),
        child: cell,
      );
    }
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: AspectRatio(aspectRatio: 1, child: cell),
    );
  }
}

/// The legend's "Gym closed" marker.
class ClosedDot extends StatelessWidget {
  const ClosedDot({super.key});

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: DashedCircle(PresenceColors.ink.withValues(alpha: 0.5)),
  );
}

class DashedCircle extends CustomPainter {
  const DashedCircle(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rect = Offset.zero & size;
    const dashes = 16;
    const sweep = 3.14159265 * 2 / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect.deflate(0.5), i * sweep, sweep * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(DashedCircle oldDelegate) => oldDelegate.color != color;
}
