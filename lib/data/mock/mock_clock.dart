/// The single source of "now". Pass [fixed] to freeze time in tests.
class MockClock {
  MockClock([this.fixed]);

  final DateTime? fixed;

  DateTime get now => fixed ?? DateTime.now();
}
