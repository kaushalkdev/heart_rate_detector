import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:hear_rate_detector/features/heart_rate/ports/camera_frame.dart';

/// Camera lifecycle + preview + frame stream. Implementations live under
/// `infrastructure/` and may use `package:camera`.
abstract class CameraSession {
  Future<void> initialize();

  /// Live preview widget; only valid after [initialize] succeeds.
  Widget buildPreview();

  /// Frames from the image stream; starts when [initialize] runs.
  Stream<CameraFrame> get frames;

  /// Still capture as encoded file bytes (e.g. JPEG from the plugin).
  Future<Uint8List?> captureStillBytes();

  Future<void> dispose();
}
