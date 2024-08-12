import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:torch_light/torch_light.dart';

class HeartRateDetector extends StatefulWidget {
  const HeartRateDetector({super.key});

  @override
  State<HeartRateDetector> createState() => _HeartRateDetectorState();
}

class _HeartRateDetectorState extends State<HeartRateDetector> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Heart Rate Detector'),
      ),
      body: Column(
        children: [
          Center(child: CameraWidget()),
        ],
      ),
    );
  }
}

class CameraWidget extends StatefulWidget {
  const CameraWidget({super.key});

  @override
  State<CameraWidget> createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget> {
  CameraFactory cameraFactory = CameraFactory.i;

  @override
  void initState() {
    // TorchLight.enableTorch();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CameraPreview>(
      future: cameraFactory.createCamera(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done &&
            snapshot.data == null) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Camera Setup Error: ${snapshot.error}');
        }
        return SizedBox(
          height: 200,
          width: 200,
          child: snapshot.data,
        );
      },
    );
  }

  @override
  void dispose() {
    cameraFactory.disposeCamera();
    super.dispose();
  }
}

class CameraFactory {
  CameraFactory._();
  static final i = CameraFactory._();

  CameraController? _controller;

  Future<CameraPreview> createCamera() async {
    try {
      var cameraDescription = await availableCameras();

      if (cameraDescription.isEmpty) {
        throw Exception('No cameras found');
      }

      _controller =
          CameraController(cameraDescription.first, ResolutionPreset.low);

      await _controller?.initialize();

      return CameraPreview(_controller!);
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  void disposeCamera() {
    _controller?.dispose();
  }
}
