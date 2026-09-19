import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hear_rate_detector/features/heart_rate/core/frame_timing_stats.dart';
import 'package:hear_rate_detector/features/heart_rate/core/red_signal.dart';
import 'package:hear_rate_detector/features/heart_rate/core/rgb_values.dart';
import 'package:hear_rate_detector/features/heart_rate/ports/camera_frame.dart';
import 'package:hear_rate_detector/features/heart_rate/ports/camera_session.dart';
import 'package:hear_rate_detector/features/heart_rate/processing/rgb_analyzer.dart';
import 'package:hear_rate_detector/features/heart_rate/processing/signal_filter.dart';
import 'package:hear_rate_detector/features/heart_rate/ui/widgets/live_preview_panel.dart';
import 'package:hear_rate_detector/features/heart_rate/ui/widgets/red_signal_chart.dart';

/// Diagnostic screen that measures the camera's natural frame delivery rate.
class FrameTimingPage extends StatefulWidget {
  const FrameTimingPage({super.key, required this.cameraSession});

  final CameraSession cameraSession;

  @override
  State<FrameTimingPage> createState() => _FrameTimingPageState();
}

class _FrameTimingPageState extends State<FrameTimingPage>
    with WidgetsBindingObserver {
  static const _signalSampleRateHz = 30.0;
  static const _minimumRedIntensity = 200.0;
  static const _signalSettlingDuration = Duration(seconds: 5);
  static const _graphAmplitudeRange = SignalAmplitudeRange(maxMagnitude: 1.44);

  final FrameTimingTracker _tracker = FrameTimingTracker();
  final RgbAnalyzer _rgbAnalyzer = RgbAnalyzer();
  final SignalFilter _signalFilter = BandPassSignalFilter(
    sampleRateHz: _signalSampleRateHz,
  );
  final RedSignalTracker _redSignalTracker = RedSignalTracker();
  FrameTimingStats _stats = const FrameTimingStats.empty();
  FrameTimingStats _latestStats = const FrameTimingStats.empty();
  SignalLogMetrics? _latestSignalMetrics;
  SignalLogMetrics? _visibleSignalMetrics;
  Duration? _captureStartedAt;
  List<RedSignalSample> _signalSamples = const [];
  StreamSubscription<CameraFrame>? _subscription;
  Timer? _displayTimer;
  bool _sessionReady = false;
  bool _initializing = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_startSession());
  }

  Future<void> _startSession() async {
    if (_initializing || _sessionReady) return;
    _initializing = true;
    try {
      await widget.cameraSession.initialize();
      if (!mounted) return;
      _subscription = widget.cameraSession.frames.listen(_onFrame);
      _displayTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (mounted) {
          setState(() {
            _stats = _latestStats;
            _visibleSignalMetrics = _latestSignalMetrics;
            _signalSamples = _redSignalTracker.samples;
          });
        }
      });
      setState(() {
        _sessionReady = true;
        _error = null;
      });
    } catch (error, stackTrace) {
      log(
        'Frame timing camera initialization failed',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() {
          _sessionReady = false;
          _error = error;
        });
      }
    } finally {
      _initializing = false;
    }
  }

  void _onFrame(CameraFrame frame) {
    _latestStats = _tracker.add(frame.arrivedAt);
    final rawRgbValues = _rgbAnalyzer.analyzeCameraFrame(frame);
    final rawRedIntensity = rawRgbValues.red;
    double? bandPassedRedIntensity;
    var captureState = SignalCaptureState.belowThreshold;
    var settlingElapsed = Duration.zero;

    if (rawRedIntensity.isFinite && rawRedIntensity >= _minimumRedIntensity) {
      final startedAt = _captureStartedAt ??= frame.arrivedAt;
      settlingElapsed = frame.arrivedAt - startedAt;
      bandPassedRedIntensity = _signalFilter.process(rawRedIntensity);
      captureState = SignalCaptureState.settling;
      if (settlingElapsed >= _signalSettlingDuration) {
        captureState = SignalCaptureState.capturing;
        _redSignalTracker.add(
          timestamp: frame.arrivedAt,
          redIntensity: bandPassedRedIntensity,
        );
      }
    } else {
      _resetSignalCapture();
    }

    _latestSignalMetrics = SignalLogMetrics(
      timestamp: frame.arrivedAt,
      rawRgbValues: rawRgbValues,
      bandPassedRedIntensity: bandPassedRedIntensity,
      captureState: captureState,
      settlingElapsed: settlingElapsed,
    );
    _logSignalMetrics(_latestSignalMetrics!);
  }

  Future<void> _stopSession() async {
    _displayTimer?.cancel();
    _displayTimer = null;
    await _subscription?.cancel();
    _subscription = null;
    _resetSignalCapture();
    _latestSignalMetrics = null;
    _visibleSignalMetrics = null;
    await widget.cameraSession.dispose();
    if (mounted) setState(() => _sessionReady = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_startSession());
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_stopSession());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _displayTimer?.cancel();
    unawaited(_subscription?.cancel());
    unawaited(widget.cameraSession.dispose());
    super.dispose();
  }

  void _resetSignalCapture() {
    _signalFilter.reset();
    _redSignalTracker.reset();
    _captureStartedAt = null;
    _signalSamples = const [];
  }

  void _logSignalMetrics(SignalLogMetrics metrics) {
    log(
      'red_signal_metrics '
      'timestamp=${metrics.formattedTimestamp} '
      'raw=${metrics.rawRedIntensity.toStringAsFixed(4)} '
      'raw_green=${metrics.rawRgbValues.green.toStringAsFixed(4)} '
      'raw_blue=${metrics.rawRgbValues.blue.toStringAsFixed(4)} '
      'band_passed=${metrics.bandPassedRedIntensity?.toStringAsFixed(4) ?? 'skipped'} '
      'red_threshold=$_minimumRedIntensity '
      'capture_state=${metrics.captureState.name} '
      'graph_range=${_graphAmplitudeRange.label} '
      'settling_ms=${metrics.settlingElapsed.inMilliseconds}',
      name: 'heart_rate.signal',
    );
  }

  String get _captureStatus {
    final metrics = _visibleSignalMetrics;
    if (metrics == null) return 'Waiting for frames';
    switch (metrics.captureState) {
      case SignalCaptureState.belowThreshold:
        return 'Below threshold';
      case SignalCaptureState.settling:
        final seconds = metrics.settlingElapsed.inMilliseconds / 1000;
        return 'Settling ${seconds.toStringAsFixed(1)} / '
            '${_signalSettlingDuration.inSeconds} s';
      case SignalCaptureState.capturing:
        return 'Capturing';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Heart Rate Signal')),
      body: _error != null
          ? Center(child: Text('Camera failed to start: $_error'))
          : !_sessionReady
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _CaptureOverview(
                  preview: widget.cameraSession.buildPreview(),
                  frameStats: _stats,
                  signalMetrics: _visibleSignalMetrics,
                ),
                const SizedBox(height: 16),
                _MetricRow(
                  label: 'Red threshold',
                  value: '>= ${_minimumRedIntensity.toStringAsFixed(0)}',
                ),
                _MetricRow(label: 'Capture', value: _captureStatus),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'Filtered Red Signal',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 8),
                        RedSignalChart(
                          samples: _signalSamples,
                          amplitudeRange: _graphAmplitudeRange,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _CaptureOverview extends StatelessWidget {
  const _CaptureOverview({
    required this.preview,
    required this.frameStats,
    required this.signalMetrics,
  });

  final Widget preview;
  final FrameTimingStats frameStats;
  final SignalLogMetrics? signalMetrics;

  @override
  Widget build(BuildContext context) {
    final metrics = _SignalMetricsPanel(
      metrics: signalMetrics,
      frameStats: frameStats,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 280 ||
            MediaQuery.textScalerOf(context).scale(14) > 18) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: _FingerPreview(preview: preview)),
              const SizedBox(height: 16),
              metrics,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _FingerPreview(preview: preview),
            const SizedBox(width: 16),
            Expanded(child: metrics),
          ],
        );
      },
    );
  }
}

class _FingerPreview extends StatelessWidget {
  const _FingerPreview({required this.preview});

  final Widget preview;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Place your fingertip over the red camera target',
      child: Container(
        width: 112,
        height: 112,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: colors.error, width: 3),
        ),
        child: ClipOval(child: LivePreviewPanel(preview: preview, size: 104)),
      ),
    );
  }
}

enum SignalCaptureState { belowThreshold, settling, capturing }

class SignalLogMetrics {
  const SignalLogMetrics({
    required this.timestamp,
    required this.rawRgbValues,
    required this.bandPassedRedIntensity,
    required this.captureState,
    required this.settlingElapsed,
  });

  final Duration timestamp;
  final RgbValues rawRgbValues;
  final double? bandPassedRedIntensity;
  final SignalCaptureState captureState;
  final Duration settlingElapsed;

  double get rawRedIntensity => rawRgbValues.red;

  String get formattedTimestamp {
    final totalMilliseconds = timestamp.inMilliseconds;
    final minutes = totalMilliseconds ~/ Duration.millisecondsPerMinute;
    final seconds =
        (totalMilliseconds % Duration.millisecondsPerMinute) ~/
        Duration.millisecondsPerSecond;
    final milliseconds = totalMilliseconds % Duration.millisecondsPerSecond;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '${milliseconds.toString().padLeft(3, '0')}';
  }
}

class _SignalMetricsPanel extends StatelessWidget {
  const _SignalMetricsPanel({required this.metrics, required this.frameStats});

  final SignalLogMetrics? metrics;
  final FrameTimingStats frameStats;

  @override
  Widget build(BuildContext context) {
    final metrics = this.metrics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Live statistics', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        _MetricRow(
          label: 'FPS',
          value: frameStats.averageFps.toStringAsFixed(1),
        ),
        _MetricRow(
          label: 'Frames',
          value: frameStats.framesObserved.toString(),
        ),
        _MetricRow(
          label: 'Timestamp',
          value: metrics?.formattedTimestamp ?? '--:--.---',
        ),
        const SizedBox(height: 6),
        Text('Raw RGB (0-255)', style: Theme.of(context).textTheme.labelMedium),
        _MetricRow(
          label: 'Red',
          value: metrics?.rawRgbValues.red.toStringAsFixed(2) ?? '--',
        ),
        _MetricRow(
          label: 'Green',
          value: metrics?.rawRgbValues.green.toStringAsFixed(2) ?? '--',
        ),
        _MetricRow(
          label: 'Blue',
          value: metrics?.rawRgbValues.blue.toStringAsFixed(2) ?? '--',
        ),
        const SizedBox(height: 6),
        _MetricRow(
          label: 'Filtered',
          value: metrics?.bandPassedRedIntensity?.toStringAsFixed(2) ?? '--',
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Expanded(child: Text(label, style: textTheme.bodySmall)),
          const SizedBox(width: 8),
          Text(value, textAlign: TextAlign.end, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}
