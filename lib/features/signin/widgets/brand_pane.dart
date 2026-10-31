import 'dart:math';

import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';

/// Shared chrome for both sign-in steps: ink brand pane + form column.
class SigninLayout extends StatelessWidget {
  const SigninLayout({super.key, required this.form});

  final Widget form;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, c) {
          if (c.maxWidth >= 720) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(child: BrandPane(wide: true)),
                Expanded(
                  child: SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          vertical: 32,
                          horizontal: 48,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 380),
                          child: form,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BrandPane(wide: false),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
                  child: SafeArea(top: false, child: form),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class BrandPane extends StatelessWidget {
  const BrandPane({super.key, required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final brand = Row(
      children: [
        const PresenceLogo(),
        const SizedBox(width: 10),
        Text(
          'Presence',
          style: PresenceType.sans(
            18,
            weight: FontWeight.w600,
            em: -0.01,
            color: PresenceColors.mist,
          ),
        ),
      ],
    );
    final headline = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Text(
        'See who is drifting before they leave.',
        style: PresenceType.sans(
          wide ? 40 : 28,
          height: 1.1,
          weight: FontWeight.w500,
          em: -0.025,
          color: PresenceColors.mist,
        ),
      ),
    );
    return Container(
      color: PresenceColors.ink,
      constraints: const BoxConstraints(minHeight: 240),
      child: SafeArea(
        bottom: false,
        right: !wide,
        child: Padding(
          padding: EdgeInsets.all(wide ? 48 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: wide
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.start,
            spacing: wide ? 0 : 28,
            children: [
              brand,
              const ExcludeSemantics(child: DotGrid()),
              headline,
            ],
          ),
        ),
      ),
    );
  }
}

class PresenceLogo extends StatelessWidget {
  const PresenceLogo({super.key});

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(size: Size.square(28), painter: _LogoPainter());
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawCircle(
      c,
      12,
      Paint()
        ..color = PresenceColors.teal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(c, 5, Paint()..color = PresenceColors.teal);
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) => false;
}

/// 14 × 6 decorative dots; teal fades out towards the right. Seeded, stable.
class DotGrid extends StatelessWidget {
  const DotGrid({super.key});

  static const _cols = 14, _rows = 6;
  static const double _gap = 8;
  static final List<Color> _colors = () {
    final rnd = Random(7);
    return [
      for (var i = 0; i < _cols * _rows; i++)
        rnd.nextDouble() < 1 - (i % _cols) * 0.058
            ? PresenceColors.teal.withValues(
                alpha: 0.35 + rnd.nextDouble() * 0.65,
              )
            : PresenceColors.mist.withValues(alpha: 0.09),
    ];
  }();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = min(c.maxWidth, 520.0);
        final cell = (w - _gap * (_cols - 1)) / _cols;
        return CustomPaint(
          size: Size(w, cell * _rows + _gap * (_rows - 1)),
          painter: _DotPainter(cell),
        );
      },
    );
  }
}

class _DotPainter extends CustomPainter {
  const _DotPainter(this.cell);

  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < DotGrid._colors.length; i++) {
      final x = (i % DotGrid._cols) * (cell + DotGrid._gap) + cell / 2;
      final y = (i ~/ DotGrid._cols) * (cell + DotGrid._gap) + cell / 2;
      canvas.drawCircle(
        Offset(x, y),
        cell / 2,
        Paint()..color = DotGrid._colors[i],
      );
    }
  }

  @override
  bool shouldRepaint(_DotPainter oldDelegate) => oldDelegate.cell != cell;
}
