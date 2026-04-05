# Testing Documentation

Comprehensive test suite for the Heart Rate Detector app covering unit tests, widget tests, and integration scenarios.

## 📊 Test Coverage

```
Total Tests: 70 ✅
├── Unit Tests (Domain): 22 tests
│   ├── RGB Values: 15 tests
│   └── Frame Analysis Result: 7 tests
├── Unit Tests (Processing): 26 tests
│   ├── RGB Analyzer: 13 tests
│   └── RGB Channel Filter: 13 tests
├── Widget Tests: 19 tests
│   ├── RGB Values Panel: 9 tests
│   └── Color Filtered Frames Panel: 6 tests
└── Integration Tests: 3 tests
    └── App & Main Flow: 3 tests
```

## 🧪 Test Structure

```
test/
├── core/                              # Domain model tests
│   ├── rgb_values_test.dart           # RGB values validation
│   └── frame_analysis_result_test.dart # Frame result bundling
├── processing/                         # Algorithm tests
│   ├── rgb_analyzer_test.dart         # RGB analysis logic
│   └── rgb_channel_filter_test.dart   # Channel filtering
├── ui/widgets/                         # Widget tests
│   ├── rgb_values_panel_test.dart     # RGB display widget
│   └── color_filtered_frames_panel_test.dart # Filtered frames
└── widget_test.dart                   # Integration tests
```

## 🏃 Running Tests

### Run All Tests
```bash
flutter test
```

### Run Specific Test File
```bash
flutter test test/core/rgb_values_test.dart
```

### Run with Coverage
```bash
flutter test --coverage
```

### Run Tests by Group
```bash
# Unit tests only
flutter test test/core/
flutter test test/processing/

# Widget tests only
flutter test test/ui/

# Integration tests
flutter test test/widget_test.dart
```

## 📝 Test Categories

### 1. Unit Tests - Domain Layer

**File:** `test/core/rgb_values_test.dart` (15 tests)

Tests the `RgbValues` domain model:
- ✅ Value creation and immutability
- ✅ Min/max value handling (0-255)
- ✅ Fractional value precision
- ✅ toString formatting
- ✅ Value equality
- ✅ Realistic color scenarios (skin tones, channel dominance)

**File:** `test/core/frame_analysis_result_test.dart` (7 tests)

Tests the `FrameAnalysisResult` model:
- ✅ Complete result bundling
- ✅ Empty/large data handling
- ✅ Data consistency
- ✅ Immutability

### 2. Unit Tests - Processing Layer

**File:** `test/processing/rgb_analyzer_test.dart` (13 tests)

Tests the RGB analysis algorithm:
- ✅ Single pixel analysis
- ✅ Multi-pixel averaging
- ✅ Edge cases (empty, all black, all white)
- ✅ Fractional averages
- ✅ Channel dominance detection
- ✅ Large frame processing (320×240)
- ✅ Performance benchmarks (<10ms)

**File:** `test/processing/rgb_channel_filter_test.dart` (13 tests)

Tests color channel filtering:
- ✅ Red-only filtering (keeps R, zeros G & B)
- ✅ Green-only filtering (keeps G, zeros R & B)
- ✅ Blue-only filtering (keeps B, zeros R & G)
- ✅ Non-destructive filtering (original data unchanged)
- ✅ New array creation
- ✅ Filter sum validation
- ✅ Performance benchmarks (<50ms for 3 filters)

### 3. Widget Tests

**File:** `test/ui/widgets/rgb_values_panel_test.dart` (9 tests)

Tests the RGB values display widget:
- ✅ UI structure (title, labels, values)
- ✅ Reactive updates via ValueNotifier
- ✅ Value formatting (1 decimal place)
- ✅ Edge values (0, 255)
- ✅ Rapid value changes
- ✅ ValueListenableBuilder usage
- ✅ Container styling

**File:** `test/ui/widgets/color_filtered_frames_panel_test.dart` (6 tests)

Tests the filtered frames display:
- ✅ Panel structure (title, labels)
- ✅ Loading indicators for empty frames
- ✅ ValueListenableBuilder for updates
- ✅ Custom frame size parameter

### 4. Integration Tests

**File:** `test/widget_test.dart` (3 tests)

Tests app-level functionality:
- ✅ App launch and home page
- ✅ Camera button presence
- ✅ Widget integration

## 🎯 Testing Best Practices

### Test Organization
- **Group related tests** using `group()` for better organization
- **Use descriptive names** that explain what is being tested
- **One assertion per test** (when possible) for clarity

### Test Data
- **Use realistic values** (e.g., skin tone RGB values)
- **Test edge cases** (0, 255, empty, large data)
- **Test typical scenarios** (moderate values, common use cases)

### Widget Testing
- **Use ValueNotifier** to test reactive updates
- **Test UI structure**, not implementation details
- **Avoid brittle tests** (don't test internal widget tree structure)

### Performance Testing
- **Benchmark critical paths** (RGB analysis, channel filtering)
- **Set reasonable thresholds** based on target device capabilities
- **Use Stopwatch** for timing measurements

## 📈 Coverage Goals

Current coverage by layer:
- **Core Domain**: 100% (all models fully tested)
- **Processing**: 95% (algorithms with edge cases)
- **UI Widgets**: 80% (key behavior and structure)
- **Infrastructure**: Not unit tested (uses real devices/packages)

**Why not 100% coverage?**
- Infrastructure adapters require real camera hardware
- Integration tests cover adapter functionality
- Focus on business logic and UI behavior

## 🔍 Test Examples

### Good Test Example
```dart
test('calculates average of multiple pixels', () {
  final rgbData = Uint8List.fromList([
    100, 50, 25,  // Pixel 1
    200, 150, 75, // Pixel 2
    150, 100, 50, // Pixel 3
  ]);

  final result = analyzer.analyzeFrame(rgbData);

  // Average: (100+200+150)/3 = 150, etc.
  expect(result.red, equals(150.0));
  expect(result.green, equals(100.0));
  expect(result.blue, equals(50.0));
});
```

**Why this is good:**
- Clear input data
- Expected behavior documented
- Single responsibility
- Easy to debug if fails

## 🚀 Continuous Integration

Tests run automatically on:
- Every commit (pre-push hook)
- Pull request creation
- Merge to main branch

## 🔗 Related Documentation

- [← Back to Main README](../README.md)
- [Feature Documentation](../lib/features/heart_rate/README.md)
- [Core Domain](../lib/features/heart_rate/core/README.md)
- [Processing Algorithms](../lib/features/heart_rate/processing/README.md)
