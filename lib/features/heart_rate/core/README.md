# Core Domain Layer

Contains **pure business logic** with no external dependencies. This layer represents the heart of the application - domain models and concepts that exist independently of any framework or technology.

This folder holds **product domain** types only: heart rate concepts, optical signal samples, and measurement lifecycle. It must stay free of Flutter, camera plugins, and image codecs. Supporting technical contracts live in `../ports/`; adapters in `../infrastructure/`.

## 📦 Contents

```
core/
├── rgb_values.dart              # RGB color channel values model
├── frame_analysis_result.dart   # Frame analysis output
├── measurement_session.dart     # (Future) Measurement session state
└── optical_signal_sample.dart   # (Future) Signal processing data
```

## 🎯 Domain Models

### RgbValues

**File:** `rgb_values.dart`

Represents the average RGB color values extracted from a camera frame.

```dart
class RgbValues {
  const RgbValues({
    required this.red,    // 0-255
    required this.green,  // 0-255
    required this.blue,   // 0-255
  });

  final double red;
  final double green;
  final double blue;
}
```

**Purpose:**
- Immutable value object
- Represents average color intensity per channel
- Used for displaying color channel analysis
- Foundation for optical heart rate detection

**Why doubles instead of ints?**
- Average values can be fractional (e.g., 127.5)
- More precision for signal processing
- Easier mathematical operations

---

### FrameAnalysisResult

**File:** `frame_analysis_result.dart`

Complete result of analyzing a single camera frame.

```dart
class FrameAnalysisResult {
  const FrameAnalysisResult({
    required this.rgbValues,          // Average R, G, B values
    required this.redFilteredJpeg,    // Red-only visualization
    required this.greenFilteredJpeg,  // Green-only visualization
    required this.blueFilteredJpeg,   // Blue-only visualization
  });
}
```

**Purpose:**
- Bundles related data together
- Single return type from processing pipeline
- Ensures consistency (all data from same frame)
- Simplifies async communication between isolates

---

## 🧪 Domain Principles

### 1. No External Dependencies
```dart
// ✅ GOOD - Pure Dart
class RgbValues {
  final double red;
  // ...
}

// ❌ BAD - Depends on Flutter/packages
import 'package:flutter/material.dart';
class RgbValues extends ChangeNotifier { ... }
```

### 2. Immutability
All domain models are **immutable** (`const` constructors, `final` fields):
- Thread-safe
- Easy to reason about
- No unexpected state changes
- Perfect for value-based equality

### 3. Framework Agnostic
These models could be used in:
- Flutter mobile app ✅ (current)
- Flutter web app ✅
- Dart CLI tool ✅
- Dart backend service ✅

## 📊 RGB Analysis Concept

The core concept (implemented in `../processing/rgb_analyzer.dart`):

```
Input: Interleaved RGB bytes [R,G,B,R,G,B,...]

Process:
  Calculate average for each channel across all pixels

Output:
  RgbValues(red: avg_r, green: avg_g, blue: avg_b)
```

**Why averages matter:**
- Optical heart rate detection uses subtle changes in skin color
- As blood flows, green light absorption changes slightly
- We need baseline values to detect these micro-variations
- Averaging reduces noise from individual pixels

## 🔗 Related Documentation

- [← Back to Feature README](../README.md)
- [Infrastructure Layer →](../infrastructure/README.md)
- [Processing Layer →](../processing/README.md)
