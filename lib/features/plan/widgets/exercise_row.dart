import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/models/workout.dart';
import '../../../theme/tokens.dart';
import '../../../widgets/hairline.dart';
import '../../../widgets/presence_button.dart';

class ExerciseRow extends StatelessWidget {
  const ExerciseRow({
    super.key,
    required this.exercise,
    required this.onRemove,
  });

  final Exercise exercise;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: const BoxDecoration(border: hairlineTop),
      child: Row(
        children: [
          Expanded(child: Text(exercise.name, style: PresenceType.body)),
          Text(
            exercise.sets,
            style: PresenceType.mono(13, color: PresenceColors.muted),
          ),
          const SizedBox(width: PresenceSpace.s4),
          PresenceIconButton(
            icon: LucideIcons.x,
            tooltip: 'Remove ${exercise.name}',
            iconColor: PresenceColors.muted,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
