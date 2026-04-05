import 'dart:typed_data';

/// Normalized camera frame for processing (no dependency on `package:camera`).
class CameraFrame {
  const CameraFrame({
    required this.width,
    required this.height,
    required this.yPlane,
    required this.uPlane,
    required this.vPlane,
    required this.formatGroupName,
  });

  final int width;
  final int height;
  final Uint8List yPlane;
  final Uint8List uPlane;
  final Uint8List vPlane;
  final String formatGroupName;

  String debugPlaneSummary() =>
      'plane : name $formatGroupName| \n'
      'plane 1: ${yPlane.length} \n'
      'plane 2: ${uPlane.length} \n'
      'plane 3: ${vPlane.length}';
}
