import 'package:hear_rate_detector/features/heart_rate/core/frame_analysis_result.dart';
import 'package:hear_rate_detector/features/heart_rate/ports/camera_frame.dart';
import 'package:hear_rate_detector/features/heart_rate/ports/frame_converter.dart';
import 'package:hear_rate_detector/features/heart_rate/ports/frame_encoder.dart';
import 'package:hear_rate_detector/features/heart_rate/processing/rgb_analyzer.dart';
import 'package:hear_rate_detector/features/heart_rate/processing/rgb_channel_filter.dart';

/// Orchestrates frame conversion, RGB analysis, and filtered frame generation.
class FrameProcessingPipeline {
  FrameProcessingPipeline({
    required FrameConverter converter,
    required RgbAnalyzer analyzer,
    required RgbChannelFilter filter,
    required FrameEncoder encoder,
  })  : _converter = converter,
        _analyzer = analyzer,
        _filter = filter,
        _encoder = encoder;

  final FrameConverter _converter;
  final RgbAnalyzer _analyzer;
  final RgbChannelFilter _filter;
  final FrameEncoder _encoder;

  FrameAnalysisResult analyzeFrame(CameraFrame frame) {
    // Convert YUV to RGB
    final rgb = _converter.convertToRgb(frame);

    // Analyze RGB values
    final rgbValues = _analyzer.analyzeFrame(rgb);

    // Generate filtered frames
    final redFiltered = _filter.filterRedChannel(rgb);
    final greenFiltered = _filter.filterGreenChannel(rgb);
    final blueFiltered = _filter.filterBlueChannel(rgb);

    // Encode to JPEG
    final redJpeg = _encoder.encodeJpgFromRgb(redFiltered, frame.width, frame.height);
    final greenJpeg = _encoder.encodeJpgFromRgb(greenFiltered, frame.width, frame.height);
    final blueJpeg = _encoder.encodeJpgFromRgb(blueFiltered, frame.width, frame.height);

    return FrameAnalysisResult(
      rgbValues: rgbValues,
      redFilteredJpeg: redJpeg,
      greenFilteredJpeg: greenJpeg,
      blueFilteredJpeg: blueJpeg,
    );
  }
}
