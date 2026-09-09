import 'dart:collection';

/// Current measurements from camera-frame arrival times.
class FrameTimingStats {
  const FrameTimingStats({
    required this.framesObserved,
    required this.averageFps,
    required this.latestInterval,
    required this.minimumInterval,
    required this.maximumInterval,
  });

  const FrameTimingStats.empty()
    : framesObserved = 0,
      averageFps = 0,
      latestInterval = Duration.zero,
      minimumInterval = Duration.zero,
      maximumInterval = Duration.zero;

  final int framesObserved;
  final double averageFps;
  final Duration latestInterval;
  final Duration minimumInterval;
  final Duration maximumInterval;
}

/// Calculates rolling frame timing without assuming a target frame rate.
class FrameTimingTracker {
  FrameTimingTracker({this.windowSize = 60}) : assert(windowSize > 0);

  final int windowSize;
  final ListQueue<Duration> _intervals = ListQueue<Duration>();
  Duration? _previousTimestamp;
  int _framesObserved = 0;

  FrameTimingStats add(Duration timestamp) {
    _framesObserved++;
    final previous = _previousTimestamp;
    _previousTimestamp = timestamp;

    if (previous == null || timestamp <= previous) {
      return _buildStats();
    }

    _intervals.addLast(timestamp - previous);
    if (_intervals.length > windowSize) {
      _intervals.removeFirst();
    }
    return _buildStats();
  }

  FrameTimingStats _buildStats() {
    if (_intervals.isEmpty) {
      return FrameTimingStats(
        framesObserved: _framesObserved,
        averageFps: 0,
        latestInterval: Duration.zero,
        minimumInterval: Duration.zero,
        maximumInterval: Duration.zero,
      );
    }

    var totalMicroseconds = 0;
    var minimum = _intervals.first;
    var maximum = _intervals.first;
    for (final interval in _intervals) {
      totalMicroseconds += interval.inMicroseconds;
      if (interval < minimum) minimum = interval;
      if (interval > maximum) maximum = interval;
    }
    final averageIntervalMicroseconds = totalMicroseconds / _intervals.length;

    return FrameTimingStats(
      framesObserved: _framesObserved,
      averageFps: Duration.microsecondsPerSecond / averageIntervalMicroseconds,
      latestInterval: _intervals.last,
      minimumInterval: minimum,
      maximumInterval: maximum,
    );
  }
}
