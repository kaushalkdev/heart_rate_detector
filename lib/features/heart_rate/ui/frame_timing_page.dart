import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hear_rate_detector/features/heart_rate/core/frame_timing_stats.dart';
import 'package:hear_rate_detector/features/heart_rate/core/red_signal.dart';
import 'package:hear_rate_detector/features/heart_rate/ports/camera_frame.dart';
import 'package:hear_rate_detector/features/heart_rate/ports/camera_session.dart';
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
  static const _signalMinValue = -20.0;
  static const _signalMaxValue = 20.0;
  static const _signalDifferenceMaxMagnitude = 5.0;

  final FrameTimingTracker _tracker = FrameTimingTracker();
  final RedChannelAnalyzer _redAnalyzer = const RedChannelAnalyzer();
  final SignalFilter _signalFilter = BandPassSignalFilter(
    sampleRateHz: _signalSampleRateHz,
  );
  final RedSignalTracker _redSignalTracker = RedSignalTracker(
    differenceLimit: _signalDifferenceMaxMagnitude,
  );
  final SignalAmplitudeRangeTracker _rangeTracker =
      SignalAmplitudeRangeTracker();
  FrameTimingStats _stats = const FrameTimingStats.empty();
  FrameTimingStats _latestStats = const FrameTimingStats.empty();
  SignalLogMetrics? _latestSignalMetrics;
  SignalLogMetrics? _visibleSignalMetrics;
  SignalAmplitudeRange? _suggestedRange;
  SignalAmplitudeRange? _lockedRange;
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
            _suggestedRange = _rangeTracker.suggestedRange;
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
    final rawRedIntensity = _redAnalyzer.averageRed(frame);
    final bandPassedRedIntensity = _signalFilter.process(rawRedIntensity);
    final cappedRedIntensity = _capSignalValue(bandPassedRedIntensity);

    final sample = _redSignalTracker.add(
      timestamp: frame.arrivedAt,
      redIntensity: cappedRedIntensity,
    );
    final plottedDifference = sample?.difference;
    if (plottedDifference != null) {
      _rangeTracker.add(
        timestamp: frame.arrivedAt,
        value: plottedDifference,
      );
    }
    _latestSignalMetrics = SignalLogMetrics(
      timestamp: frame.arrivedAt,
      rawRedIntensity: rawRedIntensity,
      bandPassedRedIntensity: bandPassedRedIntensity,
      cappedRedIntensity: cappedRedIntensity,
      plottedDifference: plottedDifference,
    );
    _logSignalMetrics(_latestSignalMetrics!);
  }

  Future<void> _stopSession() async {
    _displayTimer?.cancel();
    _displayTimer = null;
    await _subscription?.cancel();
    _subscription = null;
    _signalFilter.reset();
    _rangeTracker.reset();
    _suggestedRange = null;
    _lockedRange = null;
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

  double _capSignalValue(double value) {
    return value.clamp(_signalMinValue, _signalMaxValue).toDouble();
  }

  void _logSignalMetrics(SignalLogMetrics metrics) {
    log(
      'red_signal_metrics '
      'timestamp=${metrics.formattedTimestamp} '
      'raw=${metrics.rawRedIntensity.toStringAsFixed(4)} '
      'band_passed=${metrics.bandPassedRedIntensity.toStringAsFixed(4)} '
      'capped=${metrics.cappedRedIntensity.toStringAsFixed(4)} '
      'difference=${metrics.formattedDifference} '
      'suggested_range=${_rangeTracker.suggestedRange?.label ?? 'warming_up'} '
      'locked_range=${_lockedRange?.label ?? 'none'}',
      name: 'heart_rate.signal',
    );
  }

  SignalAmplitudeRange? get _activeRange => _lockedRange ?? _suggestedRange;

  void _lockSuggestedRange() {
    final suggestedRange = _suggestedRange;
    if (suggestedRange == null) return;

    setState(() {
      _lockedRange = suggestedRange;
    });
  }

  void _resetLockedRange() {
    setState(() {
      _lockedRange = null;
    });
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
                _SignalRangeControls(
                  suggestedRange: _suggestedRange,
                  lockedRange: _lockedRange,
                  onLock: _lockSuggestedRange,
                  onReset: _resetLockedRange,
                ),
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
                            'Red Signal Difference',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 8),
                        RedSignalChart(
                          samples: _signalSamples,
                          amplitudeRange: _activeRange,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _FingerPreview(preview: preview),
        const SizedBox(width: 16),
        Expanded(
          child: _SignalMetricsPanel(
            metrics: signalMetrics,
            frameStats: frameStats,
          ),
        ),
      ],
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
        child: ClipOval(
          child: LivePreviewPanel(preview: preview, size: 104),
        ),
      ),
    );
  }
}

class _SignalRangeControls extends StatelessWidget {
  const _SignalRangeControls({
    required this.suggestedRange,
    required this.lockedRange,
    required this.onLock,
    required this.onReset,
  });

  final SignalAmplitudeRange? suggestedRange;
  final SignalAmplitudeRange? lockedRange;
  final VoidCallback onLock;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final lockedRange = this.lockedRange;
    final suggestedRange = this.suggestedRange;
    final hasSuggestion = suggestedRange != null;
    final label = lockedRange == null
        ? 'Lock range: ${suggestedRange?.label ?? '--'}'
        : 'Range locked: ${lockedRange.label}';

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilledButton.icon(
          onPressed: hasSuggestion ? onLock : null,
          icon: Icon(lockedRange == null ? Icons.lock_open : Icons.lock),
          label: Text(label),
        ),
        OutlinedButton.icon(
          onPressed: lockedRange == null ? null : onReset,
          icon: const Icon(Icons.restart_alt),
          label: const Text('Reset'),
        ),
      ],
    );
  }
}

class SignalLogMetrics {
  const SignalLogMetrics({
    required this.timestamp,
    required this.rawRedIntensity,
    required this.bandPassedRedIntensity,
    required this.cappedRedIntensity,
    required this.plottedDifference,
  });

  final Duration timestamp;
  final double rawRedIntensity;
  final double bandPassedRedIntensity;
  final double cappedRedIntensity;
  final double? plottedDifference;

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

  String get formattedDifference {
    final difference = plottedDifference;
    return difference == null ? 'warming_up' : difference.toStringAsFixed(4);
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
        Text(
          'Live statistics',
          style: Theme.of(context).textTheme.titleSmall,
        ),
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
        _MetricRow(
          label: 'Raw red',
          value: metrics?.rawRedIntensity.toStringAsFixed(2) ?? '--',
        ),
        _MetricRow(
          label: 'Filtered',
          value: metrics?.bandPassedRedIntensity.toStringAsFixed(2) ?? '--',
        ),
        _MetricRow(
          label: 'Delta',
          value: metrics?.formattedDifference ?? '--',
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
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              textAlign: TextAlign.end,
              style: textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
