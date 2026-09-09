import 'package:flutter_test/flutter_test.dart';
import 'package:hear_rate_detector/features/heart_rate/core/frame_timing_stats.dart';

void main() {
  test('calculates measured FPS from actual frame timestamps', () {
    final tracker = FrameTimingTracker();

    tracker.add(Duration.zero);
    tracker.add(const Duration(microseconds: 33333));
    final stats = tracker.add(const Duration(microseconds: 66666));

    expect(stats.framesObserved, 3);
    expect(stats.averageFps, closeTo(30, 0.01));
    expect(stats.latestInterval.inMicroseconds, 33333);
  });

  test('keeps only the configured rolling interval window', () {
    final tracker = FrameTimingTracker(windowSize: 2);

    tracker.add(Duration.zero);
    tracker.add(const Duration(milliseconds: 100));
    tracker.add(const Duration(milliseconds: 200));
    final stats = tracker.add(const Duration(milliseconds: 250));

    expect(stats.averageFps, closeTo(13.33, 0.01));
    expect(stats.minimumInterval, const Duration(milliseconds: 50));
    expect(stats.maximumInterval, const Duration(milliseconds: 100));
  });
}
