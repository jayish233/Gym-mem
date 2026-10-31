import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/member_store.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/presence_button.dart';
import 'week_row.dart';

/// The one dark panel on Home.
class StreakPanel extends StatelessWidget {
  const StreakPanel({super.key, required this.store});

  final MemberStore store;

  @override
  Widget build(BuildContext context) {
    final checkedIn = store.checkedInToday;
    return Container(
      padding: const EdgeInsets.all(PresenceSpace.s24),
      decoration: BoxDecoration(
        color: PresenceColors.ink,
        borderRadius: BorderRadius.circular(PresenceRadius.hero),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: PresenceSpace.s24,
        children: [
          Semantics(
            label:
                '${store.currentStreak} day streak. Longest ${store.longestStreak}',
            excludeSemantics: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(
                  LucideIcons.flame,
                  size: 36,
                  color: PresenceColors.teal,
                ),
                const SizedBox(width: PresenceSpace.s8),
                Text(
                  '${store.currentStreak}',
                  style: PresenceType.numeral.copyWith(
                    color: PresenceColors.mist,
                  ),
                ),
                const SizedBox(width: PresenceSpace.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'day streak',
                        style: PresenceType.sans(
                          15,
                          weight: FontWeight.w500,
                          color: PresenceColors.mist,
                        ),
                      ),
                      Text(
                        'Longest ${store.longestStreak}',
                        style: PresenceType.sans(
                          13,
                          color: PresenceColors.mistOnInk75,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          WeekRow(store: store),
          PresenceButton(
            label: checkedIn ? 'Checked in today' : 'Scan to check in',
            icon: LucideIcons.scanLine,
            variant: checkedIn
                ? ButtonVariant.secondaryOnInk
                : ButtonVariant.key,
            height: 56,
            onPressed: () => context.go('/scan'),
          ),
        ],
      ),
    );
  }
}
