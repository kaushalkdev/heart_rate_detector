import 'package:flutter/foundation.dart';
import 'package:hear_rate_detector/features/heart_rate/core/frame_analysis_result.dart';
import 'package:hear_rate_detector/features/heart_rate/infrastructure/yuv420_to_rgb_converter.dart';
import 'package:hear_rate_detector/features/heart_rate/infrastructure/rgb_jpeg_encoder.dart';
import 'package:hear_rate_detector/features/heart_rate/ports/camera_frame.dart';
import 'package:hear_rate_detector/features/heart_rate/processing/rgb_analyzer.dart';
import 'package:hear_rate_detector/features/heart_rate/processing/rgb_channel_filter.dart';

/// Processes camera frames in a background isolate for better performance.
/// Uses Flutter's compute() to offload heavy processing from the UI thread.
class IsolateFrameProcessor {
  /// Processes a frame in a background isolate.
  /// This prevents UI blocking during heavy image processing operations.
  Future<FrameAnalysisResult> processFrame(CameraFrame frame) async {
    return compute(_processFrameInIsolate, frame);
  }
}

/// Top-level function that runs in the isolate.
/// Must be top-level (not a class method) for compute() to work.
FrameAnalysisResult _processFrameInIsolate(CameraFrame frame) {
  // Create instances inside the isolate
  final converter = Yuv420ToRgbConverter();
  final analyzer = RgbAnalyzer();
  final filter = RgbChannelFilter();
  // Use quality=60 for faster encoding (vs default 100)
  final encoder = RgbJpegEncoder(quality: 60);

  // Convert YUV to RGB
  final rgb = converter.convertToRgb(frame);

  // Analyze RGB values
  final rgbValues = analyzer.analyzeFrame(rgb);

  // Generate filtered frames
  final redFiltered = filter.filterRedChannel(rgb);
  final greenFiltered = filter.filterGreenChannel(rgb);
  final blueFiltered = filter.filterBlueChannel(rgb);

  // Encode to JPEG (3x faster with quality=60 vs 100)
  final redJpeg = encoder.encodeJpgFromRgb(redFiltered, frame.width, frame.height);
  final greenJpeg = encoder.encodeJpgFromRgb(greenFiltered, frame.width, frame.height);
  final blueJpeg = encoder.encodeJpgFromRgb(blueFiltered, frame.width, frame.height);

  return FrameAnalysisResult(
    rgbValues: rgbValues,
    redFilteredJpeg: redJpeg,
    greenFilteredJpeg: greenJpeg,
    blueFilteredJpeg: blueJpeg,
  );
}
