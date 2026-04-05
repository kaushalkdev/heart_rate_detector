import 'dart:typed_data';

import 'package:hear_rate_detector/features/heart_rate/ports/camera_frame.dart';

/// Converts a camera frame to interleaved RGB bytes (3 channels).
abstract class FrameConverter {
  Uint8List convertToRgb(CameraFrame frame);
}
