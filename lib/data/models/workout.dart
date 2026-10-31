class Exercise {
  const Exercise(this.name, this.sets);

  final String name;
  final String sets;
}

/// Mutable; owned and mutated only by MemberStore.
class WorkoutDay {
  WorkoutDay(this.name, this.exercises, {this.completed = false});

  String name;
  bool completed;
  final List<Exercise> exercises;

  bool get isRest => exercises.isEmpty || name.trim().toLowerCase() == 'rest';
}
