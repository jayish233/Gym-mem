import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/member_store.dart';
import '../../theme/tokens.dart';
import '../../widgets/day_cell.dart';
import '../../widgets/figure.dart';
import '../../widgets/member_scaffold.dart';
import '../../widgets/presence_button.dart';
import 'widgets/month_grid.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.store});

  final MemberStore store;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late DateTime _month = DateTime(
    widget.store.today.year,
    widget.store.today.month,
  );

  void _shift(int by) =>
      setState(() => _month = DateTime(_month.year, _month.month + by));

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final today = store.today;
        final start = store.membership.start;
        final canPrev = _month.isAfter(DateTime(start.year, start.month));
        final isCurrent = _month == DateTime(today.year, today.month);
        final summary = store.monthSummary(_month.year, _month.month);
        return MemberColumn(
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text('Attendance', style: PresenceType.pageTitle),
                  ),
                ),
                PresenceIconButton(
                  icon: LucideIcons.chevronLeft,
                  tooltip: 'Previous month',
                  style: IconButtonStyle.outline,
                  onPressed: canPrev ? () => _shift(-1) : null,
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 116),
                  child: Text(
                    DateFormat('MMMM yyyy').format(_month),
                    textAlign: TextAlign.center,
                    style: PresenceType.sans(15, weight: FontWeight.w500),
                  ),
                ),
                PresenceIconButton(
                  icon: LucideIcons.chevronRight,
                  tooltip: 'Next month',
                  style: IconButtonStyle.outline,
                  onPressed: isCurrent ? null : () => _shift(1),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: PresenceSpace.s16,
              children: [
                MonthGrid(store: store, month: _month),
                const _Legend(),
              ],
            ),
            Column(
              spacing: PresenceSpace.s20,
              children: [
                Row(
                  spacing: PresenceSpace.s24,
                  children: [
                    Expanded(
                      child: Figure(
                        label: 'Visits',
                        value: '${summary.visits}',
                      ),
                    ),
                    Expanded(
                      child: Figure(
                        label: 'Attendance',
                        value: '${summary.pct}%',
                      ),
                    ),
                  ],
                ),
                Row(
                  spacing: PresenceSpace.s24,
                  children: [
                    Expanded(
                      child: Figure(
                        label: 'Current streak',
                        value: '${store.currentStreak}',
                        highlight: true,
                      ),
                    ),
                    Expanded(
                      child: Figure(
                        label: 'Longest streak',
                        value: '${store.longestStreak}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              'Attendance is visits divided by the ${summary.openDays} days '
              'your gym has been open ${isCurrent ? 'so far this month' : 'that month'}. '
              'Closed days do not count.',
              style: PresenceType.caption,
            ),
          ],
        );
      },
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(BoxDecoration dot, String word) => Row(
      mainAxisSize: MainAxisSize.min,
      spacing: PresenceSpace.s8,
      children: [
        Container(width: 12, height: 12, decoration: dot),
        Text(word, style: PresenceType.sans(12, color: PresenceColors.muted)),
      ],
    );
    return Wrap(
      spacing: PresenceSpace.s20,
      runSpacing: PresenceSpace.s8,
      children: [
        item(
          const BoxDecoration(
            color: PresenceColors.teal,
            shape: BoxShape.circle,
          ),
          'Present',
        ),
        item(
          const BoxDecoration(
            color: PresenceColors.inkSoft,
            shape: BoxShape.circle,
          ),
          'Missed',
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: PresenceSpace.s8,
          children: [
            const SizedBox.square(dimension: 12, child: ClosedDot()),
            Text(
              'Gym closed',
              style: PresenceType.sans(12, color: PresenceColors.muted),
            ),
          ],
        ),
      ],
    );
  }
}
