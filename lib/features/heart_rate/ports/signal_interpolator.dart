import '../core/red_signal.dart';

/// Pure display interpolation over finite, strictly increasing observations.
/// Queries must be strictly increasing and within the observed domain.
/// Invalid input throws [ArgumentError]; implementations never extrapolate.
abstract interface class SignalInterpolator {
  String get id;
  List<RedSignalSample> interpolate({
    required List<RedSignalSample> samples,
    required List<Duration> queryTimes,
  });
}
