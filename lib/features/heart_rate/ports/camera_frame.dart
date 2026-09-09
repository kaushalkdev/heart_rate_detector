import 'dart:typed_data';

/// Normalized camera frame for processing (no dependency on `package:camera`).
class CameraFrame {
  const CameraFrame({
    required this.arrivedAt,
    required this.width,
    required this.height,
    required this.yPlane,
    required this.yBytesPerRow,
    required this.yBytesPerPixel,
    required this.uPlane,
    required this.uBytesPerRow,
    required this.uBytesPerPixel,
    required this.vPlane,
    required this.vBytesPerRow,
    required this.vBytesPerPixel,
    required this.formatGroupName,
  });

  /// Monotonic time since the camera stream started, recorded as soon as the
  /// frame callback reaches Dart.
  final Duration arrivedAt;
  final int width;
  final int height;
  final Uint8List yPlane;
  final int yBytesPerRow;
  final int yBytesPerPixel;
  final Uint8List uPlane;
  final int uBytesPerRow;
  final int uBytesPerPixel;
  final Uint8List vPlane;
  final int vBytesPerRow;
  final int vBytesPerPixel;
  final String formatGroupName;

  String debugPlaneSummary() =>
      'plane : name $formatGroupName| \n'
      'plane 1: ${yPlane.length} \n'
      'plane 2: ${uPlane.length} \n'
      'plane 3: ${vPlane.length}';
}
