import 'red_signal.dart';

/// Display data only. Each segment is painted independently across gaps.
class InterpolatedSignal {
  InterpolatedSignal({
    required List<List<RedSignalSample>> segments,
    required this.algorithmId,
    required this.sourceRevision,
    required this.elapsedMicroseconds,
  }) : segments = List.unmodifiable(
         segments.map((segment) => List<RedSignalSample>.unmodifiable(segment)),
       );

  final List<List<RedSignalSample>> segments;
  final String algorithmId;
  final int sourceRevision;

  /// Whole preparation cost, including validation, grid creation and strategy.
  final int elapsedMicroseconds;
}
