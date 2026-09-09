import 'dart:typed_data';

import 'package:hear_rate_detector/features/heart_rate/core/rgb_values.dart';

/// Analyzes RGB frame data to extract average color channel values.
class RgbAnalyzer {
  /// Calculates the average red, green, and blue values from interleaved RGB bytes.
  ///
  /// The [rgbData] should be in the format: R, G, B, R, G, B, ...
  /// where each pixel is represented by 3 consecutive bytes.
  RgbValues analyzeFrame(Uint8List rgbData) {
    if (rgbData.isEmpty) {
      return const RgbValues(red: 0, green: 0, blue: 0);
    }

    int totalRed = 0;
    int totalGreen = 0;
    int totalBlue = 0;

    // RGB data is interleaved: R, G, B, R, G, B, ...
    final pixelCount = rgbData.length ~/ 3;

    for (var i = 0; i < rgbData.length; i += 3) {
      totalRed += rgbData[i];
      totalGreen += rgbData[i + 1];
      totalBlue += rgbData[i + 2];
    }

    return RgbValues(
      red: totalRed / pixelCount,
      green: totalGreen / pixelCount,
      blue: totalBlue / pixelCount,
    );
  }
}
