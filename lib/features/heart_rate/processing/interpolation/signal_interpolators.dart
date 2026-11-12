import '../../core/red_signal.dart';
import '../../ports/signal_interpolator.dart';

/// Shared validation and sorted interval traversal. Times are relative seconds.
abstract class _Interpolator implements SignalInterpolator {
  const _Interpolator();

  List<double>? derivatives(List<double> h, List<double> slopes) => null;

  @override
  List<RedSignalSample> interpolate({
    required List<RedSignalSample> samples,
    required List<Duration> queryTimes,
  }) {
    for (var i = 0; i < samples.length; i++) {
      if (!samples[i].redIntensity.isFinite ||
          (i > 0 && samples[i].timestamp <= samples[i - 1].timestamp)) {
        throw ArgumentError('Samples must be finite and strictly ordered.');
      }
    }
    for (var i = 0; i < queryTimes.length; i++) {
      if (samples.isEmpty ||
          queryTimes[i] < samples.first.timestamp ||
          queryTimes[i] > samples.last.timestamp ||
          (i > 0 && queryTimes[i] <= queryTimes[i - 1])) {
        throw ArgumentError('Queries must be ordered and inside the domain.');
      }
    }
    if (queryTimes.isEmpty) return const [];
    if (samples.length == 1) return List.unmodifiable([samples.single]);
    final h = List.generate(
      samples.length - 1,
      (i) =>
          (samples[i + 1].timestamp - samples[i].timestamp).inMicroseconds /
          1e6,
    );
    final slopes = List.generate(
      h.length,
      (i) => (samples[i + 1].redIntensity - samples[i].redIntensity) / h[i],
    );
    final d = derivatives(h, slopes);
    var interval = 0;
    return List.unmodifiable(
      queryTimes.map((time) {
        while (interval < h.length - 1 &&
            time > samples[interval + 1].timestamp) {
          interval++;
        }
        final a = samples[interval];
        final b = samples[interval + 1];
        final u = (time - a.timestamp).inMicroseconds / 1e6 / h[interval];
        double value;
        if (time == a.timestamp) {
          value = a.redIntensity;
        } else if (time == b.timestamp) {
          value = b.redIntensity;
        } else if (d == null) {
          value = a.redIntensity + u * (b.redIntensity - a.redIntensity);
        } else {
          final u2 = u * u;
          final u3 = u2 * u;
          value =
              (2 * u3 - 3 * u2 + 1) * a.redIntensity +
              (u3 - 2 * u2 + u) * h[interval] * d[interval] +
              (-2 * u3 + 3 * u2) * b.redIntensity +
              (u3 - u2) * h[interval] * d[interval + 1];
        }
        return RedSignalSample(timestamp: time, redIntensity: value);
      }),
    );
  }
}

class LinearInterpolator extends _Interpolator {
  const LinearInterpolator();
  @override
  String get id => 'Linear';
}

/// Fritsch–Butland weighted harmonic slopes with one-sided endpoint limiting.
class PchipInterpolator extends _Interpolator {
  const PchipInterpolator();
  @override
  String get id => 'PCHIP';

  @override
  List<double> derivatives(List<double> h, List<double> slopes) {
    if (h.length == 1) return [slopes.single, slopes.single];
    final d = List.filled(h.length + 1, 0.0);
    for (var i = 1; i < h.length; i++) {
      final a = slopes[i - 1], b = slopes[i];
      if (a == 0 || b == 0 || a.sign != b.sign) continue;
      final w1 = 2 * h[i] + h[i - 1];
      final w2 = h[i] + 2 * h[i - 1];
      d[i] = (w1 + w2) / (w1 / a + w2 / b);
    }
    d[0] = _endpoint(h[0], h[1], slopes[0], slopes[1]);
    final k = h.length - 1;
    d[k + 1] = _endpoint(h[k], h[k - 1], slopes[k], slopes[k - 1]);
    return d;
  }

  double _endpoint(double h0, double h1, double s0, double s1) {
    final d = ((2 * h0 + h1) * s0 - h0 * s1) / (h0 + h1);
    if (d.sign != s0.sign) return 0;
    if (s0.sign != s1.sign && d.abs() > 3 * s0.abs()) return 3 * s0;
    return d;
  }
}

/// Natural spline: zero second derivatives at the two domain boundaries.
class NaturalCubicSpline extends _Interpolator {
  const NaturalCubicSpline();
  @override
  String get id => 'Natural cubic';

  @override
  List<double> derivatives(List<double> h, List<double> slopes) {
    final n = h.length + 1;
    final second = List.filled(n, 0.0);
    final upper = List.filled(n, 0.0);
    final rhs = List.filled(n, 0.0);
    for (var i = 1; i < n - 1; i++) {
      final pivot = 2 * (h[i - 1] + h[i]) - h[i - 1] * upper[i - 1];
      upper[i] = h[i] / pivot;
      rhs[i] =
          (6 * (slopes[i] - slopes[i - 1]) - h[i - 1] * rhs[i - 1]) / pivot;
    }
    for (var i = n - 2; i > 0; i--) {
      second[i] = rhs[i] - upper[i] * second[i + 1];
    }
    final d = List.filled(n, 0.0);
    for (var i = 0; i < n - 1; i++) {
      d[i] = slopes[i] - h[i] * (2 * second[i] + second[i + 1]) / 6;
    }
    d[n - 1] = slopes.last + h.last * (second[n - 2] + 2 * second.last) / 6;
    return d;
  }
}

const signalInterpolators = <SignalInterpolator>[
  LinearInterpolator(),
  PchipInterpolator(),
  NaturalCubicSpline(),
];
