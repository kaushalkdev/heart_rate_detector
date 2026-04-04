import 'dart:typed_data';

/// Filters RGB data to isolate individual color channels.
/// Useful for visualizing which colors the camera is capturing.
class RgbChannelFilter {
  /// Creates a red-only version of the RGB data.
  /// Sets green and blue channels to 0, keeping only red.
  Uint8List filterRedChannel(Uint8List rgbData) {
    final filtered = Uint8List(rgbData.length);
    
    for (var i = 0; i < rgbData.length; i += 3) {
      filtered[i] = rgbData[i];         // Red - keep original
      filtered[i + 1] = 0;              // Green - set to 0
      filtered[i + 2] = 0;              // Blue - set to 0
    }
    
    return filtered;
  }

  /// Creates a green-only version of the RGB data.
  /// Sets red and blue channels to 0, keeping only green.
  Uint8List filterGreenChannel(Uint8List rgbData) {
    final filtered = Uint8List(rgbData.length);
    
    for (var i = 0; i < rgbData.length; i += 3) {
      filtered[i] = 0;                  // Red - set to 0
      filtered[i + 1] = rgbData[i + 1]; // Green - keep original
      filtered[i + 2] = 0;              // Blue - set to 0
    }
    
    return filtered;
  }

  /// Creates a blue-only version of the RGB data.
  /// Sets red and green channels to 0, keeping only blue.
  Uint8List filterBlueChannel(Uint8List rgbData) {
    final filtered = Uint8List(rgbData.length);
    
    for (var i = 0; i < rgbData.length; i += 3) {
      filtered[i] = 0;                  // Red - set to 0
      filtered[i + 1] = 0;              // Green - set to 0
      filtered[i + 2] = rgbData[i + 2]; // Blue - keep original
    }
    
    return filtered;
  }
}
