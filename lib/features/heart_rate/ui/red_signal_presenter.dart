import 'dart:math' as math;

import '../core/interpolated_signal.dart';
import '../core/red_signal.dart';
import '../ports/signal_interpolator.dart';
import '../processing/interpolation/signal_interpolators.dart';

class RedSignalPresenter {
  RedSignalPresenter({
    SignalInterpolator interpolator = const LinearInterpolator(),
    this.gapFactor = 3,
    this.maxGridPoints = 1200,
    // Keep the public constructor name independent of the private field.
    // ignore: prefer_initializing_formals
  }) : _interpolator = interpolator {
    if (!gapFactor.isFinite || gapFactor <= 0 || maxGridPoints < 2) {
      throw ArgumentError('Invalid interpolation policy.');
    }
  }

  static const visibleWindow = Duration(seconds: 6);
  final double gapFactor;
  final int maxGridPoints;
  SignalInterpolator _interpolator;
  SignalInterpolator get interpolator => _interpolator;
  InterpolatedSignal? _cached;
  (int, int, int)? _key;

  void selectAlgorithm(SignalInterpolator value) {
    _interpolator = value;
    clear();
  }

  void clear() {
    _cached = null;
    _key = null;
  }

  /// Caller increments revision whenever observations or the session change.
  InterpolatedSignal prepare(
    List<RedSignalSample> samples, {
    required int revision,
    required double plotWidth,
  }) {
    if (!plotWidth.isFinite || plotWidth < 0) {
      throw ArgumentError('Invalid width');
    }
    final count = plotWidth.ceil().clamp(2, maxGridPoints);
    final end = samples.isEmpty ? 0 : samples.last.timestamp.inMicroseconds;
    final key = (revision, count, end);
    if (key == _key && _cached != null) return _cached!;
    final watch = Stopwatch()..start();
    final intervals = <int>[];
    for (var i = 1; i < samples.length; i++) {
      final dt =
          (samples[i].timestamp - samples[i - 1].timestamp).inMicroseconds;
      if (dt <= 0) {
        throw ArgumentError('Observations must be strictly ordered.');
      }
      intervals.add(dt);
    }
    intervals.sort();
    final median = intervals.isEmpty
        ? 0.0
        : intervals.length.isOdd
        ? intervals[intervals.length ~/ 2].toDouble()
        : (intervals[intervals.length ~/ 2 - 1] +
                  intervals[intervals.length ~/ 2]) /
              2;
    final groups = <List<RedSignalSample>>[];
    var current = <RedSignalSample>[];
    for (final sample in samples) {
      if (!sample.redIntensity.isFinite) {
        if (current.isNotEmpty) groups.add(current);
        current = [];
        continue;
      }
      if (current.isNotEmpty &&
          (sample.timestamp - current.last.timestamp).inMicroseconds >
              median * gapFactor) {
        groups.add(current);
        current = [];
      }
      current.add(sample);
    }
    if (current.isNotEmpty) groups.add(current);
    final start = end - visibleWindow.inMicroseconds;
    final segments = <List<RedSignalSample>>[];
    for (final group in groups) {
      if (group.last.timestamp.inMicroseconds < start) continue;
      var firstVisible = 0;
      while (firstVisible < group.length &&
          group[firstVisible].timestamp.inMicroseconds < start) {
        firstVisible++;
      }
      final support = group.sublist(math.max(0, firstVisible - 2));
      final lo = math.max(start, support.first.timestamp.inMicroseconds);
      final hi = support.last.timestamp.inMicroseconds;
      final queries = <int>{lo, hi};
      for (var i = 0; i < count; i++) {
        final time =
            start + (visibleWindow.inMicroseconds * i / (count - 1)).round();
        if (time >= lo && time <= hi) queries.add(time);
      }
      for (final sample in support) {
        if (sample.timestamp.inMicroseconds >= lo) {
          queries.add(sample.timestamp.inMicroseconds);
        }
      }
      final sorted = queries.toList()..sort();
      segments.add(
        _interpolator.interpolate(
          samples: support,
          queryTimes: sorted.map((us) => Duration(microseconds: us)).toList(),
        ),
      );
    }
    watch.stop();
    _key = key;
    return _cached = InterpolatedSignal(
      segments: segments,
      algorithmId: _interpolator.id,
      sourceRevision: revision,
      elapsedMicroseconds: watch.elapsedMicroseconds,
    );
  }
}
