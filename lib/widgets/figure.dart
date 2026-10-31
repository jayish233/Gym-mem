import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Caption above a big quiet number, with a hairline (or teal) top border.
class Figure extends StatelessWidget {
  const Figure({
    super.key,
    required this.label,
    required this.value,
    this.highlight = false,
    this.valueStyle,
    this.valueChild,
  });

  final String label;
  final String value;
  final bool highlight;
  final TextStyle? valueStyle;

  /// Replaces the [value] text, e.g. a status dot.
  final Widget? valueChild;

  @override
  Widget build(BuildContext context) {
    final style = (valueStyle ?? PresenceType.figure).copyWith(
      color: highlight ? PresenceColors.deepTeal : null,
    );
    return Container(
      padding: const EdgeInsets.only(top: PresenceSpace.s12),
      decoration: BoxDecoration(
        border: Border(
          top: highlight
              ? const BorderSide(color: PresenceColors.teal, width: 2)
              : const BorderSide(color: PresenceColors.hairline),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: PresenceType.caption),
          const SizedBox(height: PresenceSpace.s8),
          valueChild ?? Text(value, style: style),
        ],
      ),
    );
  }
}
