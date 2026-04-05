import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:hear_rate_detector/features/heart_rate/ports/camera_frame.dart';

/// Maps plugin [CameraImage] to our [CameraFrame] DTO (copies plane bytes).
class CameraFrameMapper {
  CameraFrameMapper._();

  static CameraFrame fromCameraImage(CameraImage image) {
    if (image.planes.length < 3) {
      throw StateError('Expected at least 3 image planes, got ${image.planes.length}');
    }
    return CameraFrame(
      width: image.width,
      height: image.height,
      yPlane: Uint8List.fromList(image.planes[0].bytes),
      uPlane: Uint8List.fromList(image.planes[1].bytes),
      vPlane: Uint8List.fromList(image.planes[2].bytes),
      formatGroupName: image.format.group.name,
    );
  }
}
