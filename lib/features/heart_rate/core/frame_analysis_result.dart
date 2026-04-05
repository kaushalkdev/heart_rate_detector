import 'dart:typed_data';

import 'package:hear_rate_detector/features/heart_rate/core/rgb_values.dart';

/// Result of analyzing a camera frame, containing RGB values and filtered frames.
class FrameAnalysisResult {
  const FrameAnalysisResult({
    required this.rgbValues,
    required this.redFilteredJpeg,
    required this.greenFilteredJpeg,
    required this.blueFilteredJpeg,
  });

  final RgbValues rgbValues;
  final Uint8List redFilteredJpeg;
  final Uint8List greenFilteredJpeg;
  final Uint8List blueFilteredJpeg;
}
