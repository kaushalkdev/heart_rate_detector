import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hear_rate_detector/features/heart_rate/core/rgb_values.dart';
import 'package:hear_rate_detector/features/heart_rate/ports/camera_frame.dart';
import 'package:hear_rate_detector/features/heart_rate/ports/camera_session.dart';
import 'package:hear_rate_detector/features/heart_rate/processing/isolate_frame_processor.dart';
import 'package:hear_rate_detector/features/heart_rate/infrastructure/frame_stream_policy.dart';
import 'package:hear_rate_detector/features/heart_rate/ui/widgets/color_filtered_frames_panel.dart';
import 'package:hear_rate_detector/features/heart_rate/ui/widgets/live_preview_panel.dart';
import 'package:hear_rate_detector/features/heart_rate/ui/widgets/rgb_values_panel.dart';

/// High-level capture screen: preview, RGB analysis, and color-filtered frames.
class HeartRateDetectorPage extends StatefulWidget {
  const HeartRateDetectorPage({
    super.key,
    required this.cameraSession,
    required this.processor,
  });

  final CameraSession cameraSession;
  final IsolateFrameProcessor processor;

  @override
  State<HeartRateDetectorPage> createState() => _HeartRateDetectorPageState();
}

class _HeartRateDetectorPageState extends State<HeartRateDetectorPage>
    with WidgetsBindingObserver {
  final FrameProcessingGate _gate = FrameProcessingGate();
  // Reduced from 200ms to 50ms for smoother visual updates (20 FPS)
  final FrameThrottle _throttle = FrameThrottle(
    minInterval: Duration(milliseconds: 50),
  );
  final ValueNotifier<RgbValues> _rgbValues = ValueNotifier<RgbValues>(
    const RgbValues(red: 0, green: 0, blue: 0),
  );
  final ValueNotifier<Uint8List> _redFrame = ValueNotifier<Uint8List>(Uint8List(0));
  final ValueNotifier<Uint8List> _greenFrame = ValueNotifier<Uint8List>(Uint8List(0));
  final ValueNotifier<Uint8List> _blueFrame = ValueNotifier<Uint8List>(Uint8List(0));

  StreamSubscription? _frameSubscription;
  bool _sessionReady = false;
  Object? _initError;

  // Keep track of the latest frame to process when gate is released
  CameraFrame? _pendingFrame;

  CameraSession get _session => widget.cameraSession;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initSession());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Dispose camera (and torch) when app goes to background or is paused
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      unawaited(_session.dispose());
    }
  }

  Future<void> _initSession() async {
    try {
      await _session.initialize();
      if (!mounted) {
        return;
      }
      setState(() {
        _sessionReady = true;
        _initError = null;
      });
      _frameSubscription = _session.frames.listen(_onFrame);
    } catch (e, st) {
      if (!mounted) {
        return;
      }
      setState(() {
        _initError = e;
        _sessionReady = false;
      });
      log('Camera init failed', error: e, stackTrace: st);
    }
  }

  void _onFrame(CameraFrame frame) {
    if (!_throttle.shouldProcess()) {
      return;
    }

    // If processing is busy, queue this frame as pending
    if (!_gate.tryAcquire()) {
      _pendingFrame = frame;
      return;
    }

    _processFrameAsync(frame);
  }

  void _processFrameAsync(CameraFrame frame) {
    // Process frame in background isolate
    widget.processor.processFrame(frame).then((result) {
      if (!mounted) {
        _gate.release();
        return;
      }

      _rgbValues.value = result.rgbValues;
      _redFrame.value = result.redFilteredJpeg;
      _greenFrame.value = result.greenFilteredJpeg;
      _blueFrame.value = result.blueFilteredJpeg;
      _gate.release();

      // Process pending frame if available
      if (_pendingFrame != null && _gate.tryAcquire()) {
        final pending = _pendingFrame!;
        _pendingFrame = null;
        _processFrameAsync(pending);
      }
    }).catchError((error) {
      log('Frame processing error', error: error);
      _gate.release();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_frameSubscription?.cancel());
    _rgbValues.dispose();
    _redFrame.dispose();
    _greenFrame.dispose();
    _blueFrame.dispose();
    unawaited(_session.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Heart Rate Detector')),
        body: Center(
          child: Text('Camera failed to start: $_initError'),
        ),
      );
    }

    if (!_sessionReady) {
      return Scaffold(
        appBar: AppBar(title: const Text('Heart Rate Detector')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Heart Rate Detector'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'Original Camera Feed',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: LivePreviewPanel(
                preview: _session.buildPreview(),
              ),
            ),
            const SizedBox(height: 24),
            ColorFilteredFramesPanel(
              redFrame: _redFrame,
              greenFrame: _greenFrame,
              blueFrame: _blueFrame,
            ),
            const SizedBox(height: 24),
            RgbValuesPanel(rgbValues: _rgbValues),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
