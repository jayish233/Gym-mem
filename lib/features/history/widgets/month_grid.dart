import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/member_store.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/day_cell.dart';

/// Weeks start Monday; leading blanks put day 1 under its weekday.
class MonthGrid extends StatelessWidget {
  const MonthGrid({super.key, required this.store, required this.month});

  final MemberStore store;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final lead = month.weekday - 1;
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final cells = <Widget>[
      for (var i = 0; i < lead; i++) const SizedBox(),
      for (var d = 1; d <= days; d++)
        _cell(DateTime(month.year, month.month, d)),
    ];
    while (cells.length % 7 != 0) {
      cells.add(const SizedBox());
    }
    Widget row(List<Widget> children) => Row(
      spacing: 6,
      children: [for (final c in children) Expanded(child: c)],
    );
    return Column(
      spacing: 6,
      children: [
        ExcludeSemantics(
          child: row([
            for (final l in 'MTWTFSS'.split(''))
              Text(
                l,
                textAlign: TextAlign.center,
                style: PresenceType.sans(12, color: PresenceColors.muted),
              ),
          ]),
        ),
        for (var i = 0; i < cells.length; i += 7) row(cells.sublist(i, i + 7)),
      ],
    );
  }

  Widget _cell(DateTime day) {
    final state = store.dayState(day);
    return DayCell(
      day: day.day,
      state: state,
      isToday: day == store.today,
      semanticLabel:
          '${DateFormat('MMMM d').format(day)}, ${dayStateWords[state]}',
    );
  }
}
