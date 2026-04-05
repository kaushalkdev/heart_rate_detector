# Processing Layer

Contains the **frame processing algorithms** and orchestration logic for RGB analysis. This layer sits between infrastructure (camera frames) and domain (RGB values), transforming raw data into meaningful insights.

## 📦 Contents

```
processing/
├── isolate_frame_processor.dart  # Background thread orchestrator
├── frame_processing_pipeline.dart # Workflow coordination
├── rgb_analyzer.dart              # RGB average calculation
└── rgb_channel_filter.dart        # Color channel separation
```

## 🔬 Components

### IsolateFrameProcessor

**File:** `isolate_frame_processor.dart`

**Purpose:** Moves heavy processing to background isolate for 60 FPS UI.

```dart
class IsolateFrameProcessor {
  Future<FrameAnalysisResult> processFrame(CameraFrame frame) async {
    return compute(_processFrameInIsolate, frame);
  }
}
```

**How it works:**
1. Main thread receives camera frame
2. Sends frame to isolate via `compute()`
3. Isolate processes (YUV→RGB, analyze, filter, encode)
4. Result returned to main thread
5. UI updates without blocking

**Why isolates?**
- **UI Smooth**: Main thread stays free for 60 FPS rendering
- **Parallel**: Processing happens simultaneously with UI
- **No Jank**: Even heavy operations don't freeze interface

**Trade-off:**
- Small overhead (~1ms) to serialize/deserialize data
- Worth it! Prevents 40ms UI freezes

---

### FrameProcessingPipeline

**File:** `frame_processing_pipeline.dart`

**Purpose:** Orchestrates the complete frame analysis workflow.

```dart
class FrameProcessingPipeline {
  FrameAnalysisResult analyzeFrame(CameraFrame frame) {
    // Step 1: Convert YUV → RGB
    final rgb = converter.convertToRgb(frame);
    
    // Step 2: Analyze RGB values
    final rgbValues = analyzer.analyzeFrame(rgb);
    
    // Step 3: Filter color channels
    final redFiltered = filter.filterRedChannel(rgb);
    final greenFiltered = filter.filterGreenChannel(rgb);
    final blueFiltered = filter.filterBlueChannel(rgb);
    
    // Step 4: Encode to JPEG
    final redJpeg = encoder.encodeJpgFromRgb(redFiltered, ...);
    final greenJpeg = encoder.encodeJpgFromRgb(greenFiltered, ...);
    final blueJpeg = encoder.encodeJpgFromRgb(blueFiltered, ...);
    
    // Step 5: Bundle results
    return FrameAnalysisResult(...);
  }
}
```

**Pipeline Flow:**
```
CameraFrame (YUV420)
        ↓
   [Convert]
        ↓
RGB Bytes [R,G,B,R,G,B,...]
        ↓
   [Analyze] ──→ RgbValues
        ↓
   [Filter] ──→ Red-only RGB
        |  ──→ Green-only RGB
        |  ──→ Blue-only RGB
        ↓
   [Encode] ──→ JPEG ×3
        ↓
FrameAnalysisResult
```

---

### RgbAnalyzer

**File:** `rgb_analyzer.dart`

**Purpose:** Calculates average red, green, and blue values from RGB data.

```dart
class RgbAnalyzer {
  RgbValues analyzeFrame(Uint8List rgbData) {
    int totalRed = 0;
    int totalGreen = 0;
    int totalBlue = 0;
    
    final pixelCount = rgbData.length ~/ 3;
    
    // RGB data is interleaved: R, G, B, R, G, B, ...
    for (var i = 0; i < rgbData.length; i += 3) {
      totalRed += rgbData[i];      // Red channel
      totalGreen += rgbData[i + 1]; // Green channel
      totalBlue += rgbData[i + 2];  // Blue channel
    }
    
    return RgbValues(
      red: totalRed / pixelCount,
      green: totalGreen / pixelCount,
      blue: totalBlue / pixelCount,
    );
  }
}
```

**Algorithm:**
```
Input: Interleaved RGB bytes
       [R₀, G₀, B₀, R₁, G₁, B₁, ..., Rₙ, Gₙ, Bₙ]
       Length = width × height × 3

Process:
  sum_r = Σ(Rᵢ) for i = 0 to n
  sum_g = Σ(Gᵢ) for i = 0 to n
  sum_b = Σ(Bᵢ) for i = 0 to n
  
Output:
  avg_r = sum_r / (n+1)
  avg_g = sum_g / (n+1)
  avg_b = sum_b / (n+1)
```

**Performance:**
- **Complexity**: O(n) where n = width × height
- **For 320×240**: ~76,800 pixels = ~230,400 bytes
- **Time**: ~2ms (very fast, just addition and division)

**Why this matters:**
- Green channel changes slightly with blood flow
- Detecting those changes = heart rate measurement
- Need baseline (average) to spot variations

---

### RgbChannelFilter

**File:** `rgb_channel_filter.dart`

**Purpose:** Creates single-channel visualizations by zeroing out other channels.

```dart
class RgbChannelFilter {
  // Red-only: [R,0,0,R,0,0,...]
  Uint8List filterRedChannel(Uint8List rgbData) {
    final filtered = Uint8List(rgbData.length);
    for (var i = 0; i < rgbData.length; i += 3) {
      filtered[i] = rgbData[i];      // Keep red
      filtered[i + 1] = 0;           // Zero green
      filtered[i + 2] = 0;           // Zero blue
    }
    return filtered;
  }
  
  // Green-only: [0,G,0,0,G,0,...]
  Uint8List filterGreenChannel(Uint8List rgbData) { ... }
  
  // Blue-only: [0,0,B,0,0,B,...]
  Uint8List filterBlueChannel(Uint8List rgbData) { ... }
}
```

**Example:**
```
Original:  [120, 80, 45, 115, 78, 43, ...]
            R    G   B   R    G   B

Red only:  [120,  0,  0, 115,  0,  0, ...]
Green only:[  0, 80,  0,   0, 78,  0, ...]
Blue only: [  0,  0, 45,   0,  0, 43, ...]
```

**Why visualize channels?**
- Shows which colors camera is actually detecting
- Helps debug lighting conditions
- Educational: see how RGB works
- Diagnostic: identify sensor issues

---

## ⚡ Performance Optimizations

### 1. Background Processing
```
❌ Before: Main thread (blocks UI)
✅ After: Isolate (UI free)
```

### 2. Smart Throttling
```dart
// Limit to 20 FPS processing
FrameThrottle(minInterval: Duration(milliseconds: 50))
```
- Camera: 30 FPS
- Processing: 20 FPS
- Prevents queue buildup

### 3. Frame Queuing
```dart
// Store latest frame if processing is busy
if (!_gate.tryAcquire()) {
  _pendingFrame = frame;  // Process after current frame
  return;
}
```
- Never processes stale data
- Always shows latest colors
- Prevents backlog

### 4. Reduced JPEG Quality
```dart
RgbJpegEncoder(quality: 60)  // vs default 100
```
- **Speed**: 3× faster encoding
- **Quality**: Minimal visual difference
- Perfect for preview frames

---

## 📊 Performance Benchmarks

| Operation | Time (320×240) | Details |
|-----------|----------------|---------|
| YUV→RGB | ~15ms | Infrastructure layer |
| RGB Analysis | ~2ms | Simple averaging |
| Channel Filter ×3 | ~5ms | Memcpy + zero bytes |
| JPEG Encode ×3 | ~20ms | Quality=60 |
| **Total** | **~42ms** | **~24 FPS capable** |

With 50ms throttle → **20 FPS** smooth updates.

---

## 🔗 Related Documentation

- [← Back to Feature README](../README.md)
- [Core Domain →](../core/README.md)
- [Infrastructure →](../infrastructure/README.md)
- [UI Components →](../ui/README.md)
