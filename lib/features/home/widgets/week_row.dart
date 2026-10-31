import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/member_store.dart';
import '../../../data/models/attendance_day.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/day_cell.dart';

/// Monday to Sunday of the current week, dark-panel variant.
class WeekRow extends StatelessWidget {
  const WeekRow({super.key, required this.store});

  final MemberStore store;

  @override
  Widget build(BuildContext context) {
    final today = store.today;
    final monday = addDays(today, 1 - today.weekday);
    return Row(
      spacing: 6,
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(child: _column(addDays(monday, i), today)),
      ],
    );
  }

  Widget _column(DateTime day, DateTime today) {
    final state = store.dayState(day);
    return Column(
      spacing: PresenceSpace.s8,
      children: [
        ExcludeSemantics(
          child: Text(
            DateFormat.E().format(day)[0],
            style: PresenceType.sans(12, color: PresenceColors.mistOnInk75),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 40),
          child: DayCell(
            day: day.day,
            state: state,
            isToday: day == today,
            onInk: true,
            fontSize: 13,
            semanticLabel:
                '${DateFormat('EEEE d').format(day)}, ${dayStateWords[state]}',
          ),
        ),
      ],
    );
  }
}
