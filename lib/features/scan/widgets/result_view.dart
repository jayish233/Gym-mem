import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';
import '../../../widgets/presence_button.dart';

/// Big circle icon, title, one line, optional extra row, one action.
class ResultView extends StatelessWidget {
  const ResultView({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
    this.positive = false,
    this.extra,
  });

  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onAction;

  /// Teal filled circle (success) instead of the ink ring.
  final bool positive;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Column(
        spacing: PresenceSpace.s28,
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: positive ? PresenceColors.teal : null,
              border: positive
                  ? null
                  : Border.all(color: PresenceColors.ink, width: 3),
            ),
            child: Icon(
              icon,
              size: positive ? 48 : 44,
              color: PresenceColors.ink,
            ),
          ),
          Column(
            spacing: PresenceSpace.s8,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: PresenceType.resultTitle,
              ),
              Text(
                body,
                textAlign: TextAlign.center,
                style: PresenceType.bodyMuted,
              ),
              ?extra,
            ],
          ),
          PresenceButton(label: action, height: 56, onPressed: onAction),
        ],
      ),
    );
  }
}
