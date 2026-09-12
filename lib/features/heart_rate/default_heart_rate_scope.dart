import 'package:hear_rate_detector/features/heart_rate/infrastructure/camera_plugin_session.dart';
import 'package:hear_rate_detector/features/heart_rate/processing/isolate_frame_processor.dart';
import 'package:hear_rate_detector/features/heart_rate/ui/heart_rate_detector_page.dart';
import 'package:hear_rate_detector/features/heart_rate/ui/frame_timing_page.dart';

/// Default production wiring: plugin camera + isolate-based frame processing.
/// All heavy processing (YUV conversion, RGB analysis, filtering, encoding)
/// happens in a background isolate to keep the UI smooth.
HeartRateDetectorPage createDefaultHeartRateDetectorPage() {
  return HeartRateDetectorPage(
    cameraSession: CameraPluginSession(),
    processor: IsolateFrameProcessor(),
  );
}

FrameTimingPage createDefaultFrameTimingPage() {
  return FrameTimingPage(cameraSession: CameraPluginSession());
}
