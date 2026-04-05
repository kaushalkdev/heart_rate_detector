import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:hear_rate_detector/features/heart_rate/ports/camera_frame.dart';
import 'package:hear_rate_detector/features/heart_rate/ports/camera_session.dart';
import 'package:hear_rate_detector/features/heart_rate/infrastructure/camera_frame_mapper.dart';

/// [CameraSession] backed by `package:camera` (only file here that imports the plugin).
class CameraPluginSession implements CameraSession {
  CameraPluginSession({
    this.resolutionPreset = ResolutionPreset.low,
  });

  final ResolutionPreset resolutionPreset;

  CameraController? _controller;
  StreamController<CameraFrame>? _frameController;
  bool _torchEnabled = false;

  @override
  Future<void> initialize() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('No cameras found');
    }
    _controller = CameraController(cameras.first, resolutionPreset);
    await _controller!.initialize();

    // Enable torch/flashlight BEFORE starting image stream
    await _enableTorch();

    _frameController = StreamController<CameraFrame>.broadcast();
    await _controller!.startImageStream((image) {
      final sink = _frameController;
      if (sink == null || sink.isClosed) {
        return;
      }
      sink.add(CameraFrameMapper.fromCameraImage(image));
    });
  }

  Future<void> _enableTorch() async {
    try {
      final controller = _controller;
      if (controller != null && controller.value.isInitialized) {
        // Use camera controller's built-in flash mode
        await controller.setFlashMode(FlashMode.torch);
        _torchEnabled = true;
        log('Torch enabled successfully');
      }
    } catch (e) {
      log('Failed to enable torch', error: e);
    }
  }

  Future<void> _disableTorch() async {
    if (_torchEnabled) {
      try {
        final controller = _controller;
        if (controller != null && controller.value.isInitialized) {
          // Disable camera flash mode
          await controller.setFlashMode(FlashMode.off);
          log('Torch disabled successfully');
        }
      } catch (e) {
        log('Failed to disable torch', error: e);
      }
      _torchEnabled = false;
    }
  }

  @override
  Widget buildPreview() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const SizedBox.shrink();
    }
    return CameraPreview(c);
  }

  @override
  Stream<CameraFrame> get frames {
    final fc = _frameController;
    if (fc == null) {
      return const Stream<CameraFrame>.empty();
    }
    return fc.stream;
  }

  @override
  Future<Uint8List?> captureStillBytes() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return null;
    }
    final file = await c.takePicture();
    return file.readAsBytes();
  }

  @override
  Future<void> dispose() async {
    // Disable torch first before cleaning up camera
    await _disableTorch();
    await _controller?.stopImageStream();
    await _frameController?.close();
    _frameController = null;
    await _controller?.dispose();
    _controller = null;
  }
}
