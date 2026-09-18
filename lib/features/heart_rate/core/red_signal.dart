import 'dart:collection';
import 'dart:math' as math;

import 'package:hear_rate_detector/features/heart_rate/ports/camera_frame.dart';

class RedSignalSample {
  const RedSignalSample({
    required this.timestamp,
    required this.redIntensity,
    required this.difference,
  });

  final Duration timestamp;
  final double redIntensity;
  final double difference;
}

/// Extracts mean red intensity from a sampled YUV420 frame.
class RedChannelAnalyzer {
  const RedChannelAnalyzer({this.pixelStep = 4}) : assert(pixelStep > 0);

  final int pixelStep;

  double averageRed(CameraFrame frame) {
    var total = 0.0;
    var samples = 0;

    for (var y = 0; y < frame.height; y += pixelStep) {
      for (var x = 0; x < frame.width; x += pixelStep) {
        final yIndex = y * frame.yBytesPerRow + x * frame.yBytesPerPixel;
        final vIndex =
            (y ~/ 2) * frame.vBytesPerRow + (x ~/ 2) * frame.vBytesPerPixel;
        if (yIndex >= frame.yPlane.length || vIndex >= frame.vPlane.length) {
          continue;
        }

        final luminance = frame.yPlane[yIndex];
        final chromaV = frame.vPlane[vIndex] - 128;
        total += (luminance + 1.140 * chromaV).clamp(0, 255);
        samples++;
      }
    }

    return samples == 0 ? 0 : total / samples;
  }
}

/// Builds a timestamped rolling series of consecutive red-frame differences.
class RedSignalTracker {
  RedSignalTracker({
    this.window = const Duration(seconds: 15),
    this.differenceLimit,
  }) : assert(differenceLimit == null || differenceLimit > 0);

  final Duration window;
  final double? differenceLimit;
  final ListQueue<RedSignalSample> _samples = ListQueue<RedSignalSample>();
  double? _previousRed;

  List<RedSignalSample> get samples => List.unmodifiable(_samples);

  RedSignalSample? add({
    required Duration timestamp,
    required double redIntensity,
  }) {
    final previous = _previousRed;
    _previousRed = redIntensity;
    if (previous == null) return null;

    final rawDifference = redIntensity - previous;
    final limit = differenceLimit;
    final difference = limit == null
        ? rawDifference
        : rawDifference.clamp(-limit, limit).toDouble();

    final sample = RedSignalSample(
      timestamp: timestamp,
      redIntensity: redIntensity,
      difference: difference,
    );
    _samples.addLast(sample);

    final cutoff = timestamp - window;
    while (_samples.isNotEmpty && _samples.first.timestamp < cutoff) {
      _samples.removeFirst();
    }

    return sample;
  }
}

class SignalAmplitudeRange {
  const SignalAmplitudeRange({required this.maxMagnitude})
      : assert(maxMagnitude > 0);

  final double maxMagnitude;

  double get min => -maxMagnitude;

  double get max => maxMagnitude;

  String get label => '+/-${maxMagnitude.toStringAsFixed(2)}';
}

class SignalDifferenceRange {
  const SignalDifferenceRange({required this.minimum, required this.maximum})
      : assert(maximum >= minimum);

  final double minimum;
  final double maximum;

  bool contains(double value) => value >= minimum && value <= maximum;

  String get label =>
      '${minimum.toStringAsFixed(2)} to ${maximum.toStringAsFixed(2)}';
}

class _AmplitudeSample {
  const _AmplitudeSample({required this.timestamp, required this.value});

  final Duration timestamp;
  final double value;
}

/// Observes recent filtered values and suggests a stable chart amplitude range.
class SignalAmplitudeRangeTracker {
  SignalAmplitudeRangeTracker({
    this.window = const Duration(seconds: 5),
    this.percentile = 0.95,
    this.paddingFactor = 1.15,
    this.minimumMagnitude = 0.5,
  })  : assert(percentile > 0 && percentile <= 1),
        assert(paddingFactor >= 1),
        assert(minimumMagnitude > 0);

  final Duration window;
  final double percentile;
  final double paddingFactor;
  final double minimumMagnitude;
  final ListQueue<_AmplitudeSample> _samples = ListQueue<_AmplitudeSample>();

  SignalAmplitudeRange? get suggestedRange {
    if (_samples.isEmpty) return null;

    final magnitudes = _samples
        .map((sample) => sample.value.abs())
        .where((value) => value.isFinite)
        .toList()
      ..sort();
    if (magnitudes.isEmpty) return null;

    final index = ((magnitudes.length - 1) * percentile).round();
    final magnitude = math.max(
      minimumMagnitude,
      magnitudes[index] * paddingFactor,
    );

    return SignalAmplitudeRange(maxMagnitude: magnitude);
  }

  void add({required Duration timestamp, required double value}) {
    _samples.addLast(_AmplitudeSample(timestamp: timestamp, value: value));

    final cutoff = timestamp - window;
    while (_samples.isNotEmpty && _samples.first.timestamp < cutoff) {
      _samples.removeFirst();
    }
  }

  void reset() {
    _samples.clear();
  }
}

/// Tracks the actual minimum and maximum signal difference in a rolling window.
class SignalDifferenceRangeTracker {
  SignalDifferenceRangeTracker({this.window = const Duration(seconds: 5)})
      : assert(window > Duration.zero);

  final Duration window;
  final ListQueue<_AmplitudeSample> _samples = ListQueue<_AmplitudeSample>();

  SignalDifferenceRange? get currentRange {
    final values = _samples
        .map((sample) => sample.value)
        .where((value) => value.isFinite);
    if (values.isEmpty) return null;

    var minimum = double.infinity;
    var maximum = double.negativeInfinity;
    for (final value in values) {
      minimum = math.min(minimum, value);
      maximum = math.max(maximum, value);
    }

    return SignalDifferenceRange(minimum: minimum, maximum: maximum);
  }

  void add({required Duration timestamp, required double difference}) {
    _samples.addLast(_AmplitudeSample(timestamp: timestamp, value: difference));

    final cutoff = timestamp - window;
    while (_samples.isNotEmpty && _samples.first.timestamp < cutoff) {
      _samples.removeFirst();
    }
  }

  void reset() {
    _samples.clear();
  }
}
