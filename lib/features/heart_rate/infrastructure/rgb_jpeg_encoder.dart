import 'dart:typed_data';

import 'package:hear_rate_detector/features/heart_rate/ports/frame_encoder.dart';
import 'package:image/image.dart' as img;

/// JPEG encoding via `package:image` (only implementation file that imports it).
class RgbJpegEncoder implements FrameEncoder {
  RgbJpegEncoder({this.quality = 60});

  /// JPEG quality (0-100). Lower = faster encoding but lower quality.
  /// 60 provides good balance between speed and visual quality.
  final int quality;

  @override
  Uint8List encodeJpgFromRgb(Uint8List rgb, int width, int height) {
    final image = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: rgb.buffer,
      bytesOffset: rgb.offsetInBytes,
      numChannels: 3,
      order: img.ChannelOrder.rgb,
    );
    return Uint8List.fromList(img.encodeJpg(image, quality: quality));
  }
}
