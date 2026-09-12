# Infrastructure Layer

Contains **adapters** that implement the port interfaces using external packages and platform-specific code. This layer bridges the gap between our domain logic and the real world (camera hardware, image libraries, etc.).

## 📦 Contents

```
infrastructure/
├── camera_plugin_session.dart    # Camera adapter (package:camera)
├── camera_frame_mapper.dart      # Maps CameraImage to CameraFrame
├── yuv420_to_rgb_converter.dart  # YUV color space conversion
├── rgb_jpeg_encoder.dart         # JPEG encoding (package:image)
└── frame_stream_policy.dart      # Frame throttling utilities
```

## 🔌 Adapters

### CameraPluginSession

**File:** `camera_plugin_session.dart`

**Implements:** `CameraSession` port

**Purpose:** Wraps the `package:camera` plugin to provide camera functionality.

```dart
class CameraPluginSession implements CameraSession {
  // Initialize camera with low resolution
  Future<void> initialize() async {
    final cameras = await availableCameras();
    _controller = CameraController(cameras.first, ResolutionPreset.low);
    await _controller!.initialize();
    
    // Enable torch for better optical signal
    await _controller!.setFlashMode(FlashMode.torch);
    
    // Start streaming YUV420 frames
    await _controller!.startImageStream(...);
  }
}
```

**Key Features:**
- ✅ Automatic torch control (on init, off on dispose)
- ✅ Lifecycle management (handles app pause/resume)
- ✅ Low resolution for performance (320x240 typ.)
- ✅ Streams YUV420 frames at 30 FPS
- ✅ Provides Flutter preview widget

**Torch Control:**
Uses camera controller's built-in `FlashMode.torch` instead of external packages for reliability.

---

### CameraFrameMapper

**File:** `camera_frame_mapper.dart`

**Purpose:** Converts plugin-specific `CameraImage` to our domain `CameraFrame` DTO.

```dart
class CameraFrameMapper {
  static CameraFrame fromCameraImage(CameraImage image) {
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
```

**Why needed?**
- Isolates domain from plugin-specific types
- Copies bytes to prevent memory issues
- Makes testing easier (mock `CameraFrame`, not `CameraImage`)

---

### Yuv420ToRgbConverter

**File:** `yuv420_to_rgb_converter.dart`

**Implements:** `FrameConverter` port

**Purpose:** Converts YUV420 planar format to interleaved RGB bytes.

```dart
class Yuv420ToRgbConverter implements FrameConverter {
  Uint8List convertToRgb(CameraFrame frame) {
    // For each pixel (x, y):
    //   Get Y, U, V values from planar buffers
    //   Apply YUV→RGB conversion formulas
    //   Store R, G, B in interleaved array
  }
}
```

**Algorithm:**
```
YUV → RGB Conversion Formulas:
  R = Y + 1.140 × V
  G = Y - 0.395 × U - 0.581 × V
  B = Y + 2.032 × U

Where:
  Y = Luminance (brightness)
  U = Blue-difference chroma
  V = Red-difference chroma
  
Values clamped to [0, 255]
```

**Performance:**
- Processes ~76,800 pixels (320×240) per frame
- Runs in background isolate (non-blocking)
- O(width × height) complexity

---

### RgbJpegEncoder

**File:** `rgb_jpeg_encoder.dart`

**Implements:** `FrameEncoder` port

**Purpose:** Encodes RGB bytes to JPEG using `package:image`.

```dart
class RgbJpegEncoder implements FrameEncoder {
  RgbJpegEncoder({this.quality = 60});
  
  final int quality;  // 0-100
  
  Uint8List encodeJpgFromRgb(Uint8List rgb, int width, int height) {
    final image = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: rgb.buffer,
      numChannels: 3,
      order: img.ChannelOrder.rgb,
    );
    return Uint8List.fromList(img.encodeJpg(image, quality: quality));
  }
}
```

**Quality Setting:**
- Default: 60% (3× faster than 100%)
- Trade-off: Speed vs visual quality
- For previews, 60% is perfect balance

---

### FrameStreamPolicy

**File:** `frame_stream_policy.dart`

**Purpose:** Utilities for controlling frame processing rate.

#### FrameThrottle
Limits processing frequency:
```dart
final throttle = FrameThrottle(
  minInterval: Duration(milliseconds: 50),  // 20 FPS max
);

if (throttle.shouldProcess()) {
  // Process frame
}
```

#### FrameProcessingGate
Prevents concurrent processing:
```dart
final gate = FrameProcessingGate();

if (gate.tryAcquire()) {
  try {
    // Process frame
  } finally {
    gate.release();
  }
}
```

**Why needed?**
- Camera streams at 30 FPS, but we process at 20 FPS
- Prevents queue buildup and memory issues
- Ensures one frame at a time in isolate

---

## 🎨 Design Patterns

### Adapter Pattern
Each infrastructure class **adapts** an external dependency to our interface:
```
External Package  →  Adapter  →  Port Interface  ←  Domain
package:camera   →  CameraPluginSession  →  CameraSession
package:image    →  RgbJpegEncoder       →  FrameEncoder
```

### Dependency Inversion Principle
```
✅ Domain depends on Port (interface)
✅ Infrastructure depends on Port (implements it)
❌ Domain does NOT depend on Infrastructure
```

This means:
- Can swap camera packages without changing domain
- Can test domain with mock adapters
- Domain stays pure and portable

---

## 📊 Performance Characteristics

| Adapter | Operation | Time | Notes |
|---------|-----------|------|-------|
| Yuv420ToRgbConverter | 320×240 | ~15ms | In isolate |
| RgbChannelFilter | Filter ×3 | ~5ms | Simple loops |
| RgbJpegEncoder | Encode ×3 | ~20ms | Quality=60 |
| **Total** | **Per frame** | **~40ms** | **25 FPS capable** |

With 50ms throttle, we achieve smooth 20 FPS updates.

---

## 🔗 Related Documentation

- [← Back to Feature README](../README.md)
- [Core Domain →](../core/README.md)
- [Processing Layer →](../processing/README.md)
