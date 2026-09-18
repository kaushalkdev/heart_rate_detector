import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_rate_detector/features/heart_rate/core/red_signal.dart';
import 'package:hear_rate_detector/features/heart_rate/ports/camera_frame.dart';

void main() {
  test('calculates average red from YUV using plane strides', () {
    final frame = CameraFrame(
      arrivedAt: Duration.zero,
      width: 2,
      height: 2,
      yPlane: Uint8List.fromList([100, 100, 100, 100]),
      yBytesPerRow: 2,
      yBytesPerPixel: 1,
      uPlane: Uint8List.fromList([128]),
      uBytesPerRow: 1,
      uBytesPerPixel: 1,
      vPlane: Uint8List.fromList([128]),
      vBytesPerRow: 1,
      vBytesPerPixel: 1,
      formatGroupName: 'yuv420',
    );

    expect(const RedChannelAnalyzer(pixelStep: 1).averageRed(frame), 100);
  });

  test('tracks signed differences and removes samples outside the window', () {
    final tracker = RedSignalTracker(window: const Duration(seconds: 2));

    final first = tracker.add(timestamp: Duration.zero, redIntensity: 100);
    final second = tracker.add(
      timestamp: const Duration(seconds: 1),
      redIntensity: 103,
    );
    tracker.add(timestamp: const Duration(seconds: 2), redIntensity: 101);
    tracker.add(timestamp: const Duration(seconds: 4), redIntensity: 106);

    expect(first, isNull);
    expect(second?.difference, 3);
    expect(tracker.samples.map((sample) => sample.difference), [-2, 5]);
  });

  test('caps tracked differences when a limit is configured', () {
    final tracker = RedSignalTracker(differenceLimit: 2);

    tracker.add(timestamp: Duration.zero, redIntensity: 100);
    final positive = tracker.add(
      timestamp: const Duration(seconds: 1),
      redIntensity: 110,
    );
    final negative = tracker.add(
      timestamp: const Duration(seconds: 2),
      redIntensity: 90,
    );

    expect(positive?.difference, 2);
    expect(negative?.difference, -2);
  });

  test('suggests symmetric amplitude range from recent signal values', () {
    final tracker = SignalAmplitudeRangeTracker(
      percentile: 1,
      paddingFactor: 1,
      minimumMagnitude: 0.5,
    );

    tracker.add(timestamp: Duration.zero, value: -2);
    tracker.add(timestamp: const Duration(seconds: 1), value: 4);

    final range = tracker.suggestedRange;

    expect(range?.min, -4);
    expect(range?.max, 4);
    expect(range?.label, '+/-4.00');
  });

  test('removes amplitude samples outside the tracking window', () {
    final tracker = SignalAmplitudeRangeTracker(
      window: const Duration(seconds: 2),
      percentile: 1,
      paddingFactor: 1,
    );

    tracker.add(timestamp: Duration.zero, value: 10);
    tracker.add(timestamp: const Duration(seconds: 3), value: 2);

    expect(tracker.suggestedRange?.maxMagnitude, 2);
  });

  test('tracks actual minimum and maximum signal differences', () {
    final tracker = SignalDifferenceRangeTracker();

    tracker.add(timestamp: Duration.zero, difference: -2.5);
    tracker.add(timestamp: const Duration(seconds: 1), difference: 1.25);
    tracker.add(timestamp: const Duration(seconds: 2), difference: 4);

    expect(tracker.currentRange?.minimum, -2.5);
    expect(tracker.currentRange?.maximum, 4);
    expect(tracker.currentRange?.label, '-2.50 to 4.00');
    expect(tracker.currentRange?.contains(-2.5), isTrue);
    expect(tracker.currentRange?.contains(4), isTrue);
    expect(tracker.currentRange?.contains(4.01), isFalse);
  });

  test('removes difference samples outside the tracking window', () {
    final tracker = SignalDifferenceRangeTracker(
      window: const Duration(seconds: 2),
    );

    tracker.add(timestamp: Duration.zero, difference: -5);
    tracker.add(timestamp: const Duration(seconds: 3), difference: 2);

    expect(tracker.currentRange?.minimum, 2);
    expect(tracker.currentRange?.maximum, 2);
  });
}
