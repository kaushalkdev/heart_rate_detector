import 'dart:math' as math;

/// Processes one scalar signal sample at a time.
///
/// Implementations are stateful so they can be used with live camera streams
/// without reprocessing the full signal window on every frame.
abstract class SignalFilter {
  double process(double sample);

  void reset();
}

class FirstOrderLowPassFilter implements SignalFilter {
  FirstOrderLowPassFilter({
    required double sampleRateHz,
    required double cutoffHz,
  })  : assert(sampleRateHz > 0),
        assert(cutoffHz > 0),
        _alpha = _lowPassAlpha(sampleRateHz, cutoffHz);

  final double _alpha;
  double? _previousOutput;

  @override
  double process(double sample) {
    final previousOutput = _previousOutput;
    if (previousOutput == null) {
      _previousOutput = sample;
      return sample;
    }

    final output = previousOutput + _alpha * (sample - previousOutput);
    _previousOutput = output;
    return output;
  }

  @override
  void reset() {
    _previousOutput = null;
  }

  static double _lowPassAlpha(double sampleRateHz, double cutoffHz) {
    final dt = 1 / sampleRateHz;
    final rc = 1 / (2 * math.pi * cutoffHz);
    return dt / (rc + dt);
  }
}

class FirstOrderHighPassFilter implements SignalFilter {
  FirstOrderHighPassFilter({
    required double sampleRateHz,
    required double cutoffHz,
  })  : assert(sampleRateHz > 0),
        assert(cutoffHz > 0),
        _alpha = _highPassAlpha(sampleRateHz, cutoffHz);

  final double _alpha;
  double? _previousInput;
  double _previousOutput = 0;

  @override
  double process(double sample) {
    final previousInput = _previousInput;
    if (previousInput == null) {
      _previousInput = sample;
      return 0;
    }

    final output = _alpha * (_previousOutput + sample - previousInput);
    _previousInput = sample;
    _previousOutput = output;
    return output;
  }

  @override
  void reset() {
    _previousInput = null;
    _previousOutput = 0;
  }

  static double _highPassAlpha(double sampleRateHz, double cutoffHz) {
    final dt = 1 / sampleRateHz;
    final rc = 1 / (2 * math.pi * cutoffHz);
    return rc / (rc + dt);
  }
}

/// Simple real-time band-pass filter for optical heart-rate signals.
///
/// The default pass band keeps typical pulse frequencies:
/// 0.5 Hz to 4.0 Hz, roughly 30 BPM to 240 BPM.
class BandPassSignalFilter implements SignalFilter {
  BandPassSignalFilter({
    required double sampleRateHz,
    double lowCutoffHz = 0.5,
    double highCutoffHz = 4.0,
  })  : assert(lowCutoffHz > 0),
        assert(highCutoffHz > lowCutoffHz),
        _highPass = FirstOrderHighPassFilter(
          sampleRateHz: sampleRateHz,
          cutoffHz: lowCutoffHz,
        ),
        _lowPass = FirstOrderLowPassFilter(
          sampleRateHz: sampleRateHz,
          cutoffHz: highCutoffHz,
        );

  final FirstOrderHighPassFilter _highPass;
  final FirstOrderLowPassFilter _lowPass;

  @override
  double process(double sample) {
    return _lowPass.process(_highPass.process(sample));
  }

  @override
  void reset() {
    _highPass.reset();
    _lowPass.reset();
  }
}

/// Caps a wrapped filter's output to a stable range for plotting/tuning.
class BoundedSignalFilter implements SignalFilter {
  BoundedSignalFilter({
    required SignalFilter filter,
    required double minValue,
    required double maxValue,
  })  : assert(maxValue > minValue),
        _filter = filter,
        _minValue = minValue,
        _maxValue = maxValue;

  final SignalFilter _filter;
  final double _minValue;
  final double _maxValue;

  @override
  double process(double sample) {
    return _filter.process(sample).clamp(_minValue, _maxValue).toDouble();
  }

  @override
  void reset() {
    _filter.reset();
  }
}
