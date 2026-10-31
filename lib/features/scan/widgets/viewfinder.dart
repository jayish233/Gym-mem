import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';

/// Square ink frame with teal corner brackets and the scan sweep (4.9).
class Viewfinder extends StatefulWidget {
  const Viewfinder({super.key, required this.child});

  final Widget child;

  @override
  State<Viewfinder> createState() => _ViewfinderState();
}

class _ViewfinderState extends State<Viewfinder>
    with SingleTickerProviderStateMixin {
  late final _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _sweep
        ..stop()
        ..value = 0.5;
    } else if (!_sweep.isAnimating) {
      _sweep.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PresenceRadius.hero),
        child: ColoredBox(
          color: PresenceColors.ink,
          child: LayoutBuilder(
            builder: (context, c) {
              final inset = c.maxWidth * 0.14;
              return Stack(
                fit: StackFit.expand,
                children: [
                  widget.child,
                  const IgnorePointer(
                    child: CustomPaint(painter: _CornersPainter()),
                  ),
                  AnimatedBuilder(
                    animation: _sweep,
                    builder: (context, _) {
                      final t = Curves.easeInOut.transform(_sweep.value);
                      return Positioned(
                        left: inset,
                        right: inset,
                        top: inset + (c.maxHeight - inset * 2) * t - 1,
                        height: 2,
                        child: ColoredBox(
                          color: PresenceColors.teal.withValues(alpha: 0.9),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CornersPainter extends CustomPainter {
  const _CornersPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final i = size.width * 0.14;
    final l = size.width * 0.1;
    final p = Paint()
      ..color = PresenceColors.teal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final r = size.width - i, b = size.height - i;
    for (final (Offset corner, double dx, double dy) in [
      (Offset(i, i), 1.0, 1.0),
      (Offset(r, i), -1.0, 1.0),
      (Offset(i, b), 1.0, -1.0),
      (Offset(r, b), -1.0, -1.0),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(corner.dx, corner.dy + l * dy)
          ..lineTo(corner.dx, corner.dy)
          ..lineTo(corner.dx + l * dx, corner.dy),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_CornersPainter oldDelegate) => false;
}
