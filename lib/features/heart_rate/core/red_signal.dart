import 'dart:collection';

import 'package:hear_rate_detector/features/heart_rate/ports/camera_frame.dart';

/// A filtered red-intensity value at a camera frame timestamp.
class RedSignalSample {
  const RedSignalSample({required this.timestamp, required this.redIntensity});

  final Duration timestamp;
  final double redIntensity;
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

/// Retains filtered intensity samples without calculating frame differences.
class RedSignalTracker {
  RedSignalTracker({this.window = const Duration(seconds: 15)})
    : assert(window > Duration.zero);

  final Duration window;
  final ListQueue<RedSignalSample> _samples = ListQueue<RedSignalSample>();

  List<RedSignalSample> get samples => List.unmodifiable(_samples);

  void add({required Duration timestamp, required double redIntensity}) {
    final sample = RedSignalSample(
      timestamp: timestamp,
      redIntensity: redIntensity,
    );
    _samples.addLast(sample);

    final cutoff = timestamp - window;
    while (_samples.isNotEmpty && _samples.first.timestamp < cutoff) {
      _samples.removeFirst();
    }
  }

  void reset() {
    _samples.clear();
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
