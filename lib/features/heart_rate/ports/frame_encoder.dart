import 'dart:typed_data';

/// Encodes interleaved RGB bytes to JPEG.
abstract class FrameEncoder {
  Uint8List encodeJpgFromRgb(Uint8List rgb, int width, int height);
}
