import 'package:flutter/material.dart';

import '../../../data/models/workout.dart';
import '../../../theme/tokens.dart';

const weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

class DayChips extends StatelessWidget {
  const DayChips({
    super.key,
    required this.plan,
    required this.selected,
    required this.today,
    required this.onSelect,
  });

  final List<WorkoutDay> plan;
  final int selected;
  final int today;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 6,
      children: [for (var i = 0; i < 7; i++) Expanded(child: _chip(i))],
    );
  }

  Widget _chip(int i) {
    final isSelected = i == selected;
    final fg = isSelected ? PresenceColors.mist : PresenceColors.ink;
    final dot = plan[i].completed
        ? PresenceColors.teal
        : i == today
        ? fg
        : Colors.transparent;
    final radius = BorderRadius.circular(PresenceRadius.member);
    return Semantics(
      button: true,
      selected: isSelected,
      label:
          '${weekdays[i]}, ${plan[i].name}${i == today ? ', today' : ''}'
          '${plan[i].completed ? ', completed' : ''}',
      excludeSemantics: true,
      child: Material(
        color: isSelected ? PresenceColors.ink : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: isSelected
              ? BorderSide.none
              : BorderSide(color: PresenceColors.ink.withValues(alpha: 0.2)),
        ),
        child: InkWell(
          borderRadius: radius,
          hoverColor: PresenceColors.ink.withValues(alpha: 0.04),
          onTap: () => onSelect(i),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: PresenceSpace.s8,
              children: [
                Text(
                  weekdays[i][0],
                  style: PresenceType.sans(
                    12,
                    weight: FontWeight.w600,
                    color: fg,
                  ),
                ),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
