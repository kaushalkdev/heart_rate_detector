# Heart Rate Detection Feature

This module contains the complete heart rate detection feature, implementing Clean Architecture principles with clear separation between domain logic, ports (interfaces), and infrastructure (implementations).

## 📐 Architecture Overview

```
heart_rate/
├── core/               # Domain layer - pure business logic
├── ports/              # Interface definitions (contracts)
├── infrastructure/     # Implementations using external packages
├── processing/         # Frame processing and RGB analysis
├── ui/                 # Flutter widgets and pages
├── default_heart_rate_scope.dart  # Dependency injection
└── heart_rate_flow.dart           # Navigation flow
```

## 🎯 Feature Flow

### 1. Permission & Navigation
**File:** `heart_rate_flow.dart`

- Requests camera permission on app start
- Navigates to detector page when granted
- Handles permission denied states

### 2. Camera Session Lifecycle
**File:** `infrastructure/camera_plugin_session.dart`

1. Initialize camera with low resolution
2. Enable torch (flashlight) for better optical signal
3. Start YUV420 frame streaming at 30 FPS
4. Monitor app lifecycle (pause/resume)
5. Cleanup on dispose (stops camera, disables torch)

### 3. Frame Processing Pipeline
**File:** `processing/isolate_frame_processor.dart`

```
Camera Frame (YUV420)
        ↓
[Background Isolate]
        ↓
YUV → RGB Conversion
        ↓
RGB Analysis (avg R,G,B)
        ↓
Channel Filtering (R-only, G-only, B-only)
        ↓
JPEG Encoding (×3 images)
        ↓
[Main Thread]
        ↓
UI Update
```

### 4. Display & Visualization
**File:** `ui/heart_rate_detector_page.dart`

- Live camera preview
- RGB value bars (animated, 0-255 scale)
- Color-filtered frame previews (R, G, B channels)
- Smooth 150ms fade transitions

## 🔌 Ports (Interfaces)

Located in `ports/` - define contracts without implementation:

| Port | Purpose | Implementations |
|------|---------|-----------------|
| `CameraSession` | Camera lifecycle & frame streaming | `CameraPluginSession` |
| `FrameConverter` | YUV → RGB conversion | `Yuv420ToRgbConverter` |
| `FrameEncoder` | RGB → JPEG encoding | `RgbJpegEncoder` |

**Why Ports?**
- **Testability**: Mock implementations for testing
- **Flexibility**: Swap implementations without changing domain logic
- **Dependency Inversion**: Domain doesn't depend on frameworks

## 🧠 Core Domain

See [Core README](core/README.md) for details.

**Key Models:**
- `RgbValues` - Represents average R, G, B channel values
- `FrameAnalysisResult` - Complete frame analysis output
- `CameraFrame` - Camera frame data transfer object

## ⚙️ Infrastructure

See [Infrastructure README](infrastructure/README.md) for details.

**Key Adapters:**
- `CameraPluginSession` - Wraps `package:camera`
- `Yuv420ToRgbConverter` - YUV color space conversion
- `RgbJpegEncoder` - JPEG compression using `package:image`

## 🔬 Processing

See [Processing README](processing/README.md) for details.

**Key Components:**
- `IsolateFrameProcessor` - Background thread processing
- `RgbAnalyzer` - Calculates average RGB values
- `RgbChannelFilter` - Extracts individual color channels
- `FrameProcessingPipeline` - Orchestrates the workflow

## 🎨 UI Components

See [UI README](ui/README.md) for details.

**Key Widgets:**
- `HeartRateDetectorPage` - Main page with lifecycle management
- `LivePreviewPanel` - Camera preview display
- `RgbValuesPanel` - Animated color bars
- `ColorFilteredFramesPanel` - R/G/B channel previews

## 📊 Performance Optimizations

1. **Background Processing**: All heavy work runs in isolates (60 FPS UI)
2. **Smart Throttling**: 50ms interval = 20 FPS updates (smooth & efficient)
3. **Frame Queuing**: Always processes latest frame (no stale data)
4. **Reduced JPEG Quality**: 60% quality = 3× faster encoding
5. **Low Camera Resolution**: Minimizes data to process

## 🔄 Dependency Injection

**File:** `default_heart_rate_scope.dart`

Wires up concrete implementations:

```dart
HeartRateDetectorPage createDefaultHeartRateDetectorPage() {
  return HeartRateDetectorPage(
    cameraSession: CameraPluginSession(),
    processor: IsolateFrameProcessor(),
  );
}
```

This is the **only** place where concrete classes are instantiated, making it easy to:
- Swap implementations
- Create test configurations
- Add new features

## 🧪 Testing Strategy

- **Unit Tests**: Test domain logic and algorithms in isolation
- **Widget Tests**: Test UI components with mock implementations
- **Integration Tests**: Test complete flow with real camera (on device)

## 📈 Future Enhancements

- [ ] Heart rate calculation from RGB signals
- [ ] Signal filtering and noise reduction
- [ ] Historical data tracking and charts
- [ ] Export data functionality
- [ ] Multiple measurement modes

## 🔗 Related Documentation

- [← Back to Main README](../../../README.md)
- [Core Domain →](core/README.md)
- [Infrastructure →](infrastructure/README.md)
- [Processing →](processing/README.md)
- [UI Components →](ui/README.md)
