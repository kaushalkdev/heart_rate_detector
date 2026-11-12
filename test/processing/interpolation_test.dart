import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_rate_detector/features/heart_rate/core/red_signal.dart';
import 'package:hear_rate_detector/features/heart_rate/processing/interpolation/signal_interpolators.dart';
import 'package:hear_rate_detector/features/heart_rate/ui/red_signal_presenter.dart';

RedSignalSample point(int ms, double y) => RedSignalSample(
  timestamp: Duration(milliseconds: ms),
  redIntensity: y,
);

void main() {
  for (final algorithm in signalInterpolators) {
    group(algorithm.id, () {
      test(
        'preserves uneven knots, constants and two-point linear fallback',
        () {
          final knots = [
            point(0, 1),
            point(37, 4),
            point(112, -2),
            point(500, 3),
          ];
          final output = algorithm.interpolate(
            samples: knots,
            queryTimes: knots.map((s) => s.timestamp).toList(),
          );
          expect(output.map((s) => s.redIntensity), [1, 4, -2, 3]);
          expect(
            algorithm
                .interpolate(
                  samples: [point(0, 1), point(100, 5)],
                  queryTimes: [const Duration(milliseconds: 25)],
                )
                .single
                .redIntensity,
            closeTo(2, 1e-12),
          );
          final constant = algorithm.interpolate(
            samples: [point(0, 2), point(37, 2), point(200, 2)],
            queryTimes: [const Duration(milliseconds: 100)],
          );
          expect(constant.single.redIntensity, closeTo(2, 1e-12));
          expect(knots.map((s) => s.redIntensity), [1, 4, -2, 3]);
        },
      );
      test('handles empty/single input and rejects invalid domains', () {
        expect(algorithm.interpolate(samples: [], queryTimes: []), isEmpty);
        expect(
          algorithm
              .interpolate(
                samples: [point(3, 7)],
                queryTimes: [const Duration(milliseconds: 3)],
              )
              .single
              .redIntensity,
          7,
        );
        for (final input in [
          [point(0, 1), point(0, 2)],
          [point(2, 1), point(1, 2)],
          [point(0, double.nan)],
          [point(0, double.infinity)],
        ]) {
          expect(
            () => algorithm.interpolate(samples: input, queryTimes: []),
            throwsArgumentError,
          );
        }
        for (final queries in [
          [const Duration(milliseconds: -1)],
          [const Duration(milliseconds: 11)],
          [Duration.zero, Duration.zero],
          [const Duration(milliseconds: 5), Duration.zero],
        ]) {
          expect(
            () => algorithm.interpolate(
              samples: [point(0, 0), point(10, 1)],
              queryTimes: queries,
            ),
            throwsArgumentError,
          );
        }
      });
      test('large timestamp offsets do not alter the curve', () {
        final input = [point(0, 0), point(30, 2), point(100, 1)];
        final offset = const Duration(days: 20000);
        final queries = [
          const Duration(milliseconds: 20),
          const Duration(milliseconds: 60),
        ];
        final a = algorithm.interpolate(samples: input, queryTimes: queries);
        final b = algorithm.interpolate(
          samples: input
              .map(
                (p) => RedSignalSample(
                  timestamp: p.timestamp + offset,
                  redIntensity: p.redIntensity,
                ),
              )
              .toList(),
          queryTimes: queries.map((t) => t + offset).toList(),
        );
        expect(a.map((s) => s.redIntensity), b.map((s) => s.redIntensity));
      });
    });
  }
  test('PCHIP does not overshoot uneven monotone or turning intervals', () {
    final input = [
      point(0, 0),
      point(13, 4),
      point(91, 4),
      point(150, -2),
      point(300, 1),
    ];
    final output = const PchipInterpolator().interpolate(
      samples: input,
      queryTimes: List.generate(301, (i) => Duration(milliseconds: i)),
    );
    var interval = 0;
    for (final p in output) {
      while (interval < input.length - 2 &&
          p.timestamp > input[interval + 1].timestamp) {
        interval++;
      }
      final a = input[interval].redIntensity,
          b = input[interval + 1].redIntensity;
      expect(
        p.redIntensity,
        inInclusiveRange(math.min(a, b) - 1e-12, math.max(a, b) + 1e-12),
      );
    }
  });
  test('natural cubic matches the analytic three-knot spline', () {
    // For (0,0), (1,1), (2,0), the first interval is 1.5x - .5x^3.
    final result = const NaturalCubicSpline().interpolate(
      samples: [point(0, 0), point(1000, 1), point(2000, 0)],
      queryTimes: [
        const Duration(milliseconds: 500),
        const Duration(milliseconds: 1500),
      ],
    );
    for (final p in result) {
      expect(p.redIntensity, closeTo(.6875, 1e-12));
    }
  });
  test('presenter splits gaps and invalid samples, caps grid and caches', () {
    final presenter = RedSignalPresenter(maxGridPoints: 20);
    final samples = [
      point(0, 0),
      point(30, 1),
      point(60, 0),
      point(500, 1),
      point(530, 0),
      point(560, double.nan),
      point(590, 1),
    ];
    final a = presenter.prepare(samples, revision: 1, plotWidth: 500);
    expect(a.segments.length, 3);
    expect(a.segments[0].last.timestamp, const Duration(milliseconds: 60));
    expect(a.segments[1].first.timestamp, const Duration(milliseconds: 500));
    expect(
      identical(a, presenter.prepare(samples, revision: 1, plotWidth: 500)),
      isTrue,
    );
    expect(
      a.segments.expand((s) => s).length,
      lessThanOrEqualTo(20 + samples.length + 6),
    );
    presenter.selectAlgorithm(const PchipInterpolator());
    final b = presenter.prepare(samples, revision: 1, plotWidth: 500);
    expect(b.algorithmId, 'PCHIP');
    expect(identical(a, b), isFalse);
    presenter.clear();
    expect(
      presenter.prepare([], revision: 2, plotWidth: 500).segments,
      isEmpty,
    );
  });
  test('presenter clips window, retains boundary support and invalidates width/revision', () {
    final presenter = RedSignalPresenter();
    final input = List.generate(16, (i) => point(i * 1000, i.toDouble()));
    final a = presenter.prepare(input, revision: 1, plotWidth: 300);
    expect(a.segments.single.first.timestamp, const Duration(seconds: 9));
    expect(a.segments.single.last.timestamp, const Duration(seconds: 15));
    expect(
      identical(a, presenter.prepare(input, revision: 1, plotWidth: 400)),
      isFalse,
    );
    expect(
      identical(a, presenter.prepare(input, revision: 2, plotWidth: 300)),
      isFalse,
    );
    expect(
      () => presenter.prepare(
        [point(1, 1), point(1, 2)],
        revision: 3,
        plotWidth: 100,
      ),
      throwsArgumentError,
    );
  });
}
