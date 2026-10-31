class Member {
  const Member({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  final String id;
  final String name;
  final String email;
  final String phone;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  String get initials => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p[0].toUpperCase())
      .join();

  Member copyWith({String? name, String? phone}) => Member(
    id: id,
    name: name ?? this.name,
    email: email,
    phone: phone ?? this.phone,
  );
}

class Gym {
  const Gym({required this.name, required this.closedWeekdays});

  final String name;

  /// [DateTime.monday] .. [DateTime.sunday].
  final Set<int> closedWeekdays;
}

class Membership {
  const Membership({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  bool isActiveOn(DateTime day) => !day.isBefore(start) && !day.isAfter(end);
}
