/// Lifecycle of a heart-rate measurement from the domain’s point of view.
enum MeasurementPhase {
  idle,
  active,
  completed,
}

class MeasurementSession {
  MeasurementSession({
    required this.phase,
    this.startedAt,
    this.endedAt,
  });

  final MeasurementPhase phase;
  final DateTime? startedAt;
  final DateTime? endedAt;
}
