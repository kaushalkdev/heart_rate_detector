# Heart Rate Detector

A Flutter mobile app that analyzes camera frames in real-time to detect optical signals for heart rate measurement, with RGB channel analysis and visualization.

![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)
![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture-green)

## 📱 Features

- **Real-time RGB Channel Analysis** - Extracts and displays average red, green, and blue values from camera frames
- **Color-Filtered Live Previews** - Shows separate red, green, and blue channel visualizations with smooth transitions
- **Automatic Torch Control** - Enables flashlight automatically for better signal detection
- **Background Processing** - Uses isolates for 60 FPS UI performance
- **Smooth Visual Experience** - 20 FPS updates with fade transitions between frames

## 🏗️ Architecture

This project follows **Clean Architecture** (Hexagonal Architecture / Ports & Adapters) principles:

```
┌─────────────────────────────────────────┐
│          Presentation Layer             │
│         (UI Widgets & Pages)            │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│           Domain Layer                  │
│     (Business Logic & Models)           │
│      - RGB Values                       │
│      - Frame Analysis                   │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│       Ports (Interfaces)                │
│  - CameraSession                        │
│  - FrameConverter                       │
│  - FrameEncoder                         │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│    Infrastructure (Adapters)            │
│  - Camera Plugin Integration            │
│  - YUV→RGB Conversion                   │
│  - JPEG Encoding                        │
└─────────────────────────────────────────┘
```

### 📚 Module Documentation

Detailed documentation for each module:

- **[Features Overview](lib/features/heart_rate/README.md)** - Heart rate detection features and architecture
- **[Core Domain](lib/features/heart_rate/core/README.md)** - Business logic and domain models
- **[Infrastructure](lib/features/heart_rate/infrastructure/README.md)** - Technical implementations and adapters
- **[Processing](lib/features/heart_rate/processing/README.md)** - RGB analysis algorithms and optimizations
- **[UI Components](lib/features/heart_rate/ui/README.md)** - Widget architecture and visual design

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.6.0)
- iOS/Android device with camera (emulator not recommended)

### Installation

```bash
# Clone the repository
git clone https://github.com/kaushalkdev/heart_rate_detector.git

# Navigate to project directory
cd heart_rate_detector

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Permissions

The app requires camera permission. On first launch, you'll be prompted to grant camera access.

## 📦 Dependencies

```yaml
camera: ^0.12.0+1          # Camera access and frame streaming
permission_handler: ^12.0.1 # Runtime permissions
image: ^4.8.0              # JPEG encoding
```

## 🎯 How It Works

1. **Camera Initialization** - Opens rear camera with low resolution and enables torch
2. **Frame Streaming** - Captures YUV420 frames at 30 FPS
3. **Background Processing** - Converts YUV to RGB in isolate (non-blocking)
4. **RGB Analysis** - Calculates average R, G, B values per frame
5. **Channel Filtering** - Creates red-only, green-only, blue-only visualizations
6. **Display** - Updates UI at 20 FPS with smooth fade transitions

See [Processing README](lib/features/heart_rate/processing/README.md) for detailed algorithms.

## 🎨 Screenshots

*(Add screenshots here once available)*

## 📊 Performance

- **UI Thread**: 60 FPS (background processing keeps it smooth)
- **Frame Analysis**: 20 FPS (throttled for optimal performance)
- **JPEG Quality**: 60% (3x faster encoding with minimal visual difference)
- **Processing**: Isolated to background thread

## 🧪 Testing

Comprehensive test suite with **70 tests** covering:
- ✅ Domain models (22 tests)
- ✅ Processing algorithms (26 tests)
- ✅ UI widgets (19 tests)
- ✅ Integration flows (3 tests)

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/core/rgb_values_test.dart
```

See [Test Documentation](test/README.md) for detailed testing guide.

## 🤝 Contributing

Contributions are welcome! Please follow the existing architecture patterns and add tests for new features.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Clean Architecture principles by Robert C. Martin
- Flutter camera plugin team
- Image processing algorithms based on standard YUV→RGB conversion

---

**Built with ❤️ using Flutter**
