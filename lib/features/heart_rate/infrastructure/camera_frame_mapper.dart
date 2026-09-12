import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:hear_rate_detector/features/heart_rate/ports/camera_frame.dart';

/// Maps plugin [CameraImage] to our [CameraFrame] DTO (copies plane bytes).
class CameraFrameMapper {
  CameraFrameMapper._();

  static CameraFrame fromCameraImage(
    CameraImage image, {
    required Duration arrivedAt,
  }) {
    if (image.planes.length < 3) {
      throw StateError(
        'Expected at least 3 image planes, got ${image.planes.length}',
      );
    }
    return CameraFrame(
      arrivedAt: arrivedAt,
      width: image.width,
      height: image.height,
      yPlane: Uint8List.fromList(image.planes[0].bytes),
      yBytesPerRow: image.planes[0].bytesPerRow,
      yBytesPerPixel: image.planes[0].bytesPerPixel ?? 1,
      uPlane: Uint8List.fromList(image.planes[1].bytes),
      uBytesPerRow: image.planes[1].bytesPerRow,
      uBytesPerPixel: image.planes[1].bytesPerPixel ?? 1,
      vPlane: Uint8List.fromList(image.planes[2].bytes),
      vBytesPerRow: image.planes[2].bytesPerRow,
      vBytesPerPixel: image.planes[2].bytesPerPixel ?? 1,
      formatGroupName: image.format.group.name,
    );
  }
}
