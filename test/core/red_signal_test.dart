import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_rate_detector/features/heart_rate/core/red_signal.dart';
import 'package:hear_rate_detector/features/heart_rate/ports/camera_frame.dart';

void main() {
  test('calculates average red from YUV using plane strides', () {
    final frame = CameraFrame(
      arrivedAt: Duration.zero,
      width: 2,
      height: 2,
      yPlane: Uint8List.fromList([100, 100, 100, 100]),
      yBytesPerRow: 2,
      yBytesPerPixel: 1,
      uPlane: Uint8List.fromList([128]),
      uBytesPerRow: 1,
      uBytesPerPixel: 1,
      vPlane: Uint8List.fromList([128]),
      vBytesPerRow: 1,
      vBytesPerPixel: 1,
      formatGroupName: 'yuv420',
    );

    expect(const RedChannelAnalyzer(pixelStep: 1).averageRed(frame), 100);
  });
}
