/// Skips frames while a synchronous or asynchronous processing step is in flight
/// to avoid exhausting [ImageReader] buffers.
class FrameProcessingGate {
  bool _busy = false;

  bool tryAcquire() {
    if (_busy) {
      return false;
    }
    _busy = true;
    return true;
  }

  void release() {
    _busy = false;
  }
}

/// Limits how often frames are accepted (e.g. cap FPS before heavy CPU work).
class FrameThrottle {
  FrameThrottle({this.minInterval = const Duration(milliseconds: 200)});

  final Duration minInterval;
  DateTime? _lastAccepted;

  /// Returns true if this frame should be processed (and updates last time).
  bool shouldProcess() {
    final now = DateTime.now();
    if (_lastAccepted == null || now.difference(_lastAccepted!) >= minInterval) {
      _lastAccepted = now;
      return true;
    }
    return false;
  }
}
