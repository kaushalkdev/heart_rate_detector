# UI Layer

Contains **Flutter widgets and pages** that present data to the user and handle interactions. This layer depends on domain models and ports, but never directly on infrastructure implementations.

## 📦 Contents

```
ui/
├── heart_rate_detector_page.dart   # Main page with lifecycle
└── widgets/
    ├── live_preview_panel.dart           # Camera preview
    ├── rgb_values_panel.dart             # RGB color bars
    └── color_filtered_frames_panel.dart  # R/G/B channel previews
```

## 🎨 Widgets

### HeartRateDetectorPage

**File:** `heart_rate_detector_page.dart`

**Purpose:** Main page that orchestrates the entire RGB analysis experience.

**Key Responsibilities:**
1. **Lifecycle Management**
   - Implements `WidgetsBindingObserver`
   - Monitors app state (active, paused, detached)
   - Cleans up camera and torch on exit

2. **Frame Processing Coordination**
   - Subscribes to camera frame stream
   - Throttles processing (20 FPS)
   - Manages processing gate (one at a time)
   - Queues pending frames

3. **State Management**
   - RGB values (`ValueNotifier<RgbValues>`)
   - Filtered frame bytes (`ValueNotifier<Uint8List>` ×3)
   - Preview widget from camera session

**Lifecycle Flow:**
```
initState()
    ↓
Add lifecycle observer
    ↓
Initialize camera session
    ↓
Subscribe to frame stream ──→ Process frames
    ↓                              ↓
App active                    Update UI
    ↓
App paused/killed
    ↓
didChangeAppLifecycleState()
    ↓
Dispose camera (disables torch)
    ↓
dispose()
    ↓
Remove lifecycle observer
```

**Frame Processing Flow:**
```dart
void _onFrame(CameraFrame frame) {
  // Throttle: Skip if too soon
  if (!_throttle.shouldProcess()) return;
  
  // Gate: Skip if still processing
  if (!_gate.tryAcquire()) {
    _pendingFrame = frame;  // Queue latest
    return;
  }
  
  // Process in background
  widget.processor.processFrame(frame).then((result) {
    _rgbValues.value = result.rgbValues;
    _redFrame.value = result.redFilteredJpeg;
    _greenFrame.value = result.greenFilteredJpeg;
    _blueFrame.value = result.blueFilteredJpeg;
    _gate.release();
    
    // Process pending if available
    if (_pendingFrame != null) { ... }
  });
}
```

---

### LivePreviewPanel

**File:** `live_preview_panel.dart`

**Purpose:** Displays the live camera feed.

```dart
class LivePreviewPanel extends StatelessWidget {
  const LivePreviewPanel({
    required this.preview,  // Widget from camera
    this.size = 200,
  });
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: preview,
    );
  }
}
```

**Simple & Focused:**
- Just wraps camera preview widget
- Fixed size for consistent layout
- No rotation (shows original orientation)

---

### RgbValuesPanel

**File:** `rgb_values_panel.dart`

**Purpose:** Displays RGB channel values as animated color bars.

**Features:**
- ✨ Real-time updates via `ValueListenableBuilder`
- 📊 Horizontal bars scaled 0-255
- 🎨 Color-coded (red, green, blue)
- 🎯 Numeric values displayed (e.g., "180.5")

**Visual Design:**
```
┌─────────────────────────────┐
│   RGB Channel Values        │
├─────────────────────────────┤
│ Red    ████████░░ 180.3     │
│ Green  ██░░░░░░░░  45.2     │
│ Blue   ░░░░░░░░░░   8.1     │
└─────────────────────────────┘
```

**Implementation:**
```dart
Widget _buildColorBar(String label, double value, Color color) {
  final percentage = (value / 255.0).clamp(0.0, 1.0);
  
  return Column(
    children: [
      Row([
        Text(label),  // "Red"
        Text(value.toStringAsFixed(1)),  // "180.3"
      ]),
      // Progress bar
      Stack([
        Container(color: Colors.grey[200]),  // Background
        Container(
          width: percentage * maxWidth,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              color.withOpacity(0.6),
              color,
            ]),
          ),
        ),
      ]),
    ],
  );
}
```

**Why gradients?**
- More visually appealing
- Shows "energy" / "intensity"
- Better than flat colors

---

### ColorFilteredFramesPanel

**File:** `color_filtered_frames_panel.dart`

**Purpose:** Shows red-only, green-only, blue-only camera previews.

**Features:**
- ✨ **Smooth Fade Transitions** - 150ms crossfade between frames
- 🔄 **90° Rotation** - Rotates frames upright
- 🎨 **Three Previews** - Side-by-side R, G, B channels
- ⚡ **No Flicker** - Uses `gaplessPlayback: true`

**Visual Layout:**
```
┌──────────────────────────────────┐
│    Color Channel Previews        │
├──────────────────────────────────┤
│  [Red]    [Green]    [Blue]      │
│  ┌───┐    ┌───┐      ┌───┐      │
│  │▓▓▓│    │░░░│      │   │      │
│  │▓▓▓│    │░░░│      │   │      │
│  └───┘    └───┘      └───┘      │
└──────────────────────────────────┘
```

**Key Implementation:**
```dart
AnimatedSwitcher(
  duration: Duration(milliseconds: 150),
  switchInCurve: Curves.easeIn,
  switchOutCurve: Curves.easeOut,
  child: Transform.rotate(
    key: ValueKey<int>(data.hashCode),
    angle: 1.5708,  // 90° in radians
    child: Image.memory(
      data,
      fit: BoxFit.cover,
      gaplessPlayback: true,
    ),
  ),
)
```

**Why AnimatedSwitcher?**
- Automatically fades between children when key changes
- Key = data.hashCode (new frame = new key)
- Smooth transitions instead of jarring updates

**Why Transform.rotate?**
- Camera frames are 90° tilted
- Rotation makes them upright
- Only applied to filtered frames, not main preview

---

## 🎭 Animation & Transitions

### Fade Transitions
- **Duration**: 150ms (sweet spot for smoothness)
- **Curve**: Ease-in/out (natural acceleration)
- **Trigger**: Frame data changes (hash-based key)

### Color Bars
- **Update**: Instant (ValueNotifier)
- **Visual**: Smooth (gradient makes movement feel fluid)
- **Layout**: LayoutBuilder for responsive width

---

## 📱 Responsive Design

### Layout Strategy
```dart
SingleChildScrollView(
  child: Column([
    // Camera preview (fixed size)
    LivePreviewPanel(size: 200),
    
    // Filtered frames (adaptive)
    ColorFilteredFramesPanel(frameSize: 100),
    
    // RGB bars (fill width)
    RgbValuesPanel(),
  ]),
)
```

### Considerations:
- **Fixed sizes** for camera previews (consistent UX)
- **Margins** for breathing room
- **ScrollView** for small screens
- **Material Design** principles (shadows, borders, spacing)

---

## 🎨 Design Decisions

### Why ValueNotifier instead of setState?
```dart
// ✅ Efficient - rebuilds only the listener widget
ValueListenableBuilder<RgbValues>(
  valueListenable: _rgbValues,
  builder: (context, values, child) => ...,
)

// ❌ Inefficient - rebuilds entire page
setState(() {
  _rgbValues = newValues;
});
```

### Why separate widgets?
- **Modularity**: Each widget has one job
- **Reusability**: Can use panels elsewhere
- **Testability**: Test widgets independently
- **Readability**: Smaller, focused code

### Why Container decorations?
```dart
BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(12),
  boxShadow: [BoxShadow(...)],
)
```
- Modern Material Design look
- Visual hierarchy (cards stand out)
- Professional polish

---

## 🔗 Related Documentation

- [← Back to Feature README](../README.md)
- [Core Domain →](../core/README.md)
- [Processing →](../processing/README.md)
