import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hear_rate_detector/features/heart_rate/core/frame_timing_stats.dart';
import 'package:hear_rate_detector/features/heart_rate/core/red_signal.dart';
import 'package:hear_rate_detector/features/heart_rate/ports/camera_frame.dart';
import 'package:hear_rate_detector/features/heart_rate/ports/camera_session.dart';
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
  final FrameTimingTracker _tracker = FrameTimingTracker();
  final RedChannelAnalyzer _redAnalyzer = const RedChannelAnalyzer();
  final RedSignalTracker _redSignalTracker = RedSignalTracker();
  FrameTimingStats _stats = const FrameTimingStats.empty();
  FrameTimingStats _latestStats = const FrameTimingStats.empty();
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
    _redSignalTracker.add(
      timestamp: frame.arrivedAt,
      redIntensity: _redAnalyzer.averageRed(frame),
    );
  }

  Future<void> _stopSession() async {
    _displayTimer?.cancel();
    _displayTimer = null;
    await _subscription?.cancel();
    _subscription = null;
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

  double _milliseconds(Duration duration) => duration.inMicroseconds / 1000;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera Frame Timing')),
      body: _error != null
          ? Center(child: Text('Camera failed to start: $_error'))
          : !_sessionReady
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Natural camera stream with rear camera and torch enabled. No FPS is requested.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Center(
                  child: LivePreviewPanel(
                    preview: widget.cameraSession.buildPreview(),
                    size: 280,
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Measured FPS: ${_stats.averageFps.toStringAsFixed(2)}',
                        ),
                        Text('Frames observed: ${_stats.framesObserved}'),
                        Text(
                          'Latest interval: ${_milliseconds(_stats.latestInterval).toStringAsFixed(2)} ms',
                        ),
                        Text(
                          'Minimum interval: ${_milliseconds(_stats.minimumInterval).toStringAsFixed(2)} ms',
                        ),
                        Text(
                          'Maximum interval: ${_milliseconds(_stats.maximumInterval).toStringAsFixed(2)} ms',
                        ),
                      ],
                    ),
                  ),
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
                        RedSignalChart(samples: _signalSamples),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
