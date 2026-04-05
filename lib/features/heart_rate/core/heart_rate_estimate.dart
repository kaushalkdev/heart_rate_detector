/// A single heart-rate measurement result from domain logic (not from UI or camera).
class HeartRateEstimate {
  const HeartRateEstimate({
    required this.beatsPerMinute,
    required this.at,
    this.confidence,
  });

  final int beatsPerMinute;
  final DateTime at;

  /// Optional 0.0–1.0 confidence when the estimator supports it.
  final double? confidence;
}
