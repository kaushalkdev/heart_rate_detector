import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_rate_detector/features/heart_rate/processing/signal_filter.dart';

void main() {
  group('FirstOrderLowPassFilter', () {
    test('smooths sudden changes', () {
      final filter = FirstOrderLowPassFilter(
        sampleRateHz: 30,
        cutoffHz: 2,
      );

      filter.process(0);
      final firstStep = filter.process(100);
      final secondStep = filter.process(100);

      expect(firstStep, greaterThan(0));
      expect(firstStep, lessThan(100));
      expect(secondStep, greaterThan(firstStep));
      expect(secondStep, lessThan(100));
    });

    test('reset clears previous output', () {
      final filter = FirstOrderLowPassFilter(
        sampleRateHz: 30,
        cutoffHz: 2,
      );

      filter.process(0);
      filter.process(100);
      filter.reset();

      expect(filter.process(50), 50);
    });
  });

  group('FirstOrderHighPassFilter', () {
    test('attenuates constant signal', () {
      final filter = FirstOrderHighPassFilter(
        sampleRateHz: 30,
        cutoffHz: 0.7,
      );

      var output = 0.0;
      for (var i = 0; i < 120; i++) {
        output = filter.process(100);
      }

      expect(output.abs(), lessThan(1));
    });

    test('responds to changes', () {
      final filter = FirstOrderHighPassFilter(
        sampleRateHz: 30,
        cutoffHz: 0.7,
      );

      filter.process(100);
      final output = filter.process(110);

      expect(output, greaterThan(0));
    });
  });

  group('BandPassSignalFilter', () {
    test('attenuates constant red intensity baseline', () {
      final filter = BandPassSignalFilter(sampleRateHz: 30);

      var output = 0.0;
      for (var i = 0; i < 180; i++) {
        output = filter.process(150);
      }

      expect(output.abs(), lessThan(1));
    });

    test('keeps pulse-range oscillation stronger than slow drift', () {
      const sampleRateHz = 30.0;
      final pulseFilter = BandPassSignalFilter(sampleRateHz: sampleRateHz);
      final driftFilter = BandPassSignalFilter(sampleRateHz: sampleRateHz);

      final pulsePeak = _peakFilteredMagnitude(
        pulseFilter,
        sampleRateHz: sampleRateHz,
        frequencyHz: 1.2,
      );
      final driftPeak = _peakFilteredMagnitude(
        driftFilter,
        sampleRateHz: sampleRateHz,
        frequencyHz: 0.2,
      );

      expect(pulsePeak, greaterThan(driftPeak * 2));
    });

    test('reset clears filter state', () {
      final filter = BandPassSignalFilter(sampleRateHz: 30);

      filter.process(100);
      filter.process(120);
      filter.reset();

      expect(filter.process(100), 0);
    });
  });
}

double _peakFilteredMagnitude(
  SignalFilter filter, {
  required double sampleRateHz,
  required double frequencyHz,
}) {
  var peak = 0.0;

  for (var i = 0; i < sampleRateHz * 6; i++) {
    final t = i / sampleRateHz;
    final sample = 150 + 10 * math.sin(2 * math.pi * frequencyHz * t);
    final output = filter.process(sample);

    if (i > sampleRateHz * 2) {
      peak = math.max(peak, output.abs());
    }
  }

  return peak;
}
