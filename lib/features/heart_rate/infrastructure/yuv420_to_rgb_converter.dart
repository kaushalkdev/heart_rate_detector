import 'dart:typed_data';

import 'package:hear_rate_detector/features/heart_rate/ports/camera_frame.dart';
import 'package:hear_rate_detector/features/heart_rate/ports/frame_converter.dart';

/// YUV420 planar to interleaved RGB (same algorithm as the original prototype).
class Yuv420ToRgbConverter implements FrameConverter {
  @override
  Uint8List convertToRgb(CameraFrame frame) {
    return _yuvToRgb(frame);
  }

  Uint8List _yuvToRgb(CameraFrame frame) {
    final width = frame.width;
    final height = frame.height;
    final rgb = Uint8List(width * height * 3);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final yIndex = y * frame.yBytesPerRow + x * frame.yBytesPerPixel;
        final uIndex =
            (y ~/ 2) * frame.uBytesPerRow + (x ~/ 2) * frame.uBytesPerPixel;
        final vIndex =
            (y ~/ 2) * frame.vBytesPerRow + (x ~/ 2) * frame.vBytesPerPixel;

        final yValue = frame.yPlane[yIndex];
        final uValue = frame.uPlane[uIndex] - 128;
        final vValue = frame.vPlane[vIndex] - 128;

        final r = (yValue + 1.140 * vValue).round().clamp(0, 255);
        final g = (yValue - 0.395 * uValue - 0.581 * vValue).round().clamp(
          0,
          255,
        );
        final b = (yValue + 2.032 * uValue).round().clamp(0, 255);

        final rgbIndex = (y * width + x) * 3;
        rgb[rgbIndex] = r;
        rgb[rgbIndex + 1] = g;
        rgb[rgbIndex + 2] = b;
      }
    }

    return rgb;
  }
}
