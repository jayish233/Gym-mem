import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum DotKind { present, pending, interested, issue, suspended, closed }

/// A status is always a dot plus a word (section 4.2).
class StatusDot extends StatelessWidget {
  const StatusDot({
    super.key,
    required this.kind,
    required this.word,
    this.color = PresenceColors.ink,
  });

  final DotKind kind;
  final String word;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final (Color fill, Color? ring) = switch (kind) {
      DotKind.present => (PresenceColors.teal, null),
      DotKind.pending => (PresenceColors.ink, null),
      DotKind.interested => (PresenceColors.deepTeal, null),
      DotKind.issue => (PresenceColors.paper, PresenceColors.deepTeal),
      DotKind.suspended => (PresenceColors.muted, null),
      DotKind.closed => (PresenceColors.paper, PresenceColors.ink),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: ring == null ? null : Border.all(color: ring, width: 2),
          ),
        ),
        const SizedBox(width: PresenceSpace.s8),
        Flexible(
          child: Text(
            word,
            style: PresenceType.sans(
              20,
              height: 1.2,
              weight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
