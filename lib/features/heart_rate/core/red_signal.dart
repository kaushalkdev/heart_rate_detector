import 'dart:collection';

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
  RedSignalTracker({this.window = const Duration(seconds: 15)});

  final Duration window;
  final ListQueue<RedSignalSample> _samples = ListQueue<RedSignalSample>();
  double? _previousRed;

  List<RedSignalSample> get samples => List.unmodifiable(_samples);

  void add({required Duration timestamp, required double redIntensity}) {
    final previous = _previousRed;
    _previousRed = redIntensity;
    if (previous == null) return;

    _samples.addLast(
      RedSignalSample(
        timestamp: timestamp,
        redIntensity: redIntensity,
        difference: redIntensity - previous,
      ),
    );

    final cutoff = timestamp - window;
    while (_samples.isNotEmpty && _samples.first.timestamp < cutoff) {
      _samples.removeFirst();
    }
  }
}
