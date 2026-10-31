import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/member_store.dart';
import '../../theme/tokens.dart';
import '../../widgets/avatar.dart';
import '../../widgets/hairline.dart';
import '../../widgets/member_scaffold.dart';
import '../../widgets/presence_button.dart';
import 'widgets/streak_panel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.store});

  final MemberStore store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final now = store.clock.now;
        final greeting = now.hour < 12
            ? 'morning'
            : now.hour < 17
            ? 'afternoon'
            : 'evening';
        final workout = store.plan[store.todayIndex];
        final summary = store.monthSummary(store.today.year, store.today.month);
        return MemberColumn(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: PresenceSpace.s4,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'Good $greeting, ${store.member.firstName}',
                          style: PresenceType.pageTitle,
                        ),
                      ),
                      Text(
                        store.gymName,
                        style: PresenceType.sans(
                          14,
                          color: PresenceColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Avatar(initials: store.member.initials, size: 44),
              ],
            ),
            StreakPanel(store: store),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Today · ${workout.name}',
                        style: PresenceType.section,
                      ),
                    ),
                    PresenceButton(
                      label: 'Edit plan',
                      variant: ButtonVariant.text,
                      textStyle: PresenceType.sans(
                        13,
                        color: PresenceColors.deepTeal,
                      ),
                      onPressed: () => context.go('/plan'),
                    ),
                  ],
                ),
                const SizedBox(height: PresenceSpace.s8),
                if (workout.isRest)
                  _row(
                    Text(
                      'Rest day. Nothing planned.',
                      style: PresenceType.bodyMuted,
                    ),
                  )
                else
                  for (final e in workout.exercises)
                    _row(
                      Row(
                        children: [
                          Expanded(
                            child: Text(e.name, style: PresenceType.body),
                          ),
                          Text(
                            e.sets,
                            style: PresenceType.mono(
                              13,
                              color: PresenceColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
            Container(
              padding: const EdgeInsets.only(top: PresenceSpace.s20),
              decoration: const BoxDecoration(border: hairlineTop),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.end,
                runSpacing: PresenceSpace.s12,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: PresenceSpace.s4,
                    children: [
                      Text(
                        DateFormat.MMMM().format(now),
                        style: PresenceType.caption,
                      ),
                      Text(
                        '${summary.visits} visits',
                        style: PresenceType.figure,
                      ),
                      Text(
                        '${summary.pct}% of ${summary.openDays} open days so far',
                        style: PresenceType.caption,
                      ),
                    ],
                  ),
                  PresenceButton(
                    label: 'View calendar',
                    variant: ButtonVariant.text,
                    textStyle: PresenceType.sans(14, weight: FontWeight.w500),
                    onPressed: () => context.go('/history'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _row(Widget child) => Container(
    constraints: const BoxConstraints(minHeight: 52),
    alignment: Alignment.centerLeft,
    decoration: const BoxDecoration(border: hairlineTop),
    child: child,
  );
}
