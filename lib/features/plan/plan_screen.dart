import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/member_store.dart';
import '../../theme/tokens.dart';
import '../../widgets/hairline.dart';
import '../../widgets/member_scaffold.dart';
import '../../widgets/presence_button.dart';
import '../../widgets/presence_text_field.dart';
import 'widgets/day_chips.dart';
import 'widgets/exercise_row.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key, required this.store});

  final MemberStore store;

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  late int _day = widget.store.todayIndex;

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => MemberColumn(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: PresenceSpace.s4,
            children: [
              Semantics(
                header: true,
                child: Text('Workout planner', style: PresenceType.pageTitle),
              ),
              Text(
                'Your week. Only you can see it.',
                style: PresenceType.sans(14, color: PresenceColors.muted),
              ),
            ],
          ),
          DayChips(
            plan: store.plan,
            selected: _day,
            today: store.todayIndex,
            onSelect: (i) => setState(() => _day = i),
          ),
          // Keyed so each day gets fresh text controllers.
          _DayEditor(key: ValueKey(_day), store: store, day: _day),
        ],
      ),
    );
  }
}

class _DayEditor extends StatefulWidget {
  const _DayEditor({super.key, required this.store, required this.day});

  final MemberStore store;
  final int day;

  @override
  State<_DayEditor> createState() => _DayEditorState();
}

class _DayEditorState extends State<_DayEditor> {
  late final _name = TextEditingController(
    text: widget.store.plan[widget.day].name,
  );
  final _exercise = TextEditingController();
  final _sets = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _exercise.dispose();
    _sets.dispose();
    super.dispose();
  }

  void _add() {
    widget.store.addExercise(widget.day, _exercise.text, _sets.text);
    _exercise.clear();
    _sets.clear();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final workout = store.plan[widget.day];
    final isToday = widget.day == store.todayIndex;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: PresenceSpace.s20,
      children: [
        Text(
          '${weekdays[widget.day]}${isToday ? ' · Today' : ''}',
          style: PresenceType.caption,
        ),
        Semantics(
          label: 'Workout name',
          child: TextField(
            controller: _name,
            onChanged: (v) => store.renameDay(widget.day, v),
            style: PresenceType.sans(
              32,
              height: 1.1,
              weight: FontWeight.w600,
              em: -0.025,
            ),
            decoration: const InputDecoration(
              hintText: 'Workout name',
              isDense: true,
              contentPadding: EdgeInsets.only(bottom: 10),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: PresenceColors.hairline),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: PresenceColors.deepTeal,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (workout.exercises.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: PresenceSpace.s20,
                ),
                decoration: const BoxDecoration(border: hairlineTop),
                child: Text(
                  'No exercises. Add one below, or keep it as a rest day.',
                  style: PresenceType.sans(14, color: PresenceColors.muted),
                ),
              ),
            for (var i = 0; i < workout.exercises.length; i++)
              ExerciseRow(
                exercise: workout.exercises[i],
                onRemove: () => store.removeExercise(widget.day, i),
              ),
            Container(
              padding: const EdgeInsets.only(top: PresenceSpace.s16),
              decoration: const BoxDecoration(border: hairlineTop),
              child: Row(
                spacing: PresenceSpace.s8,
                children: [
                  Expanded(
                    child: PresenceTextField(
                      controller: _exercise,
                      hint: 'Exercise',
                      semanticLabel: 'Exercise',
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  SizedBox(
                    width: 92,
                    child: PresenceTextField(
                      controller: _sets,
                      hint: '3 × 10',
                      semanticLabel: 'Sets',
                      mono: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _add(),
                    ),
                  ),
                  PresenceIconButton(
                    icon: LucideIcons.plus,
                    tooltip: 'Add exercise',
                    style: IconButtonStyle.ink,
                    size: 52,
                    onPressed: _add,
                  ),
                ],
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: PresenceSpace.s8,
          children: [
            Semantics(
              toggled: workout.completed,
              child: PresenceButton(
                label: workout.completed ? 'Completed' : 'Mark as completed',
                variant: workout.completed
                    ? ButtonVariant.key
                    : ButtonVariant.secondary,
                onPressed: () => store.toggleCompleted(widget.day),
              ),
            ),
            Text(
              'This is for your own tracking. It does not check you in at the gym.',
              style: PresenceType.caption,
            ),
          ],
        ),
      ],
    );
  }
}
