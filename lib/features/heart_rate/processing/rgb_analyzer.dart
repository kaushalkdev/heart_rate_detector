import 'dart:typed_data';

import 'package:hear_rate_detector/features/heart_rate/core/rgb_values.dart';
import 'package:hear_rate_detector/features/heart_rate/ports/camera_frame.dart';

/// Analyzes RGB frame data to extract average color channel values.
class RgbAnalyzer {
  /// Averages sampled YUV420 pixels without allocating a full RGB image.
  /// Uses the red-signal conversion's precision for consistent calibration.
  RgbValues analyzeCameraFrame(CameraFrame frame, {int pixelStep = 4}) {
    assert(pixelStep > 0);
    var totalRed = 0.0;
    var totalGreen = 0.0;
    var totalBlue = 0.0;
    var sampleCount = 0;

    for (var y = 0; y < frame.height; y += pixelStep) {
      for (var x = 0; x < frame.width; x += pixelStep) {
        final yIndex = y * frame.yBytesPerRow + x * frame.yBytesPerPixel;
        final uIndex =
            (y ~/ 2) * frame.uBytesPerRow + (x ~/ 2) * frame.uBytesPerPixel;
        final vIndex =
            (y ~/ 2) * frame.vBytesPerRow + (x ~/ 2) * frame.vBytesPerPixel;
        if (yIndex >= frame.yPlane.length ||
            uIndex >= frame.uPlane.length ||
            vIndex >= frame.vPlane.length) {
          continue;
        }

        final luminance = frame.yPlane[yIndex];
        final chromaU = frame.uPlane[uIndex] - 128;
        final chromaV = frame.vPlane[vIndex] - 128;
        totalRed += (luminance + 1.140 * chromaV).clamp(0, 255);
        totalGreen += (luminance - 0.395 * chromaU - 0.581 * chromaV).clamp(
          0,
          255,
        );
        totalBlue += (luminance + 2.032 * chromaU).clamp(0, 255);
        sampleCount++;
      }
    }

    if (sampleCount == 0) {
      return const RgbValues(red: 0, green: 0, blue: 0);
    }
    return RgbValues(
      red: totalRed / sampleCount,
      green: totalGreen / sampleCount,
      blue: totalBlue / sampleCount,
    );
  }

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
