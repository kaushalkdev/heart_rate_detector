import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
        title: const Text('Heart Rate Detector'),
      ),
      body: const Column(
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

  CameraPreview? cameraPreview;

  ValueNotifier<String> heartRate = ValueNotifier<String>('');

  @override
  void initState() {
    cameraFactory.createCamera().then((controller) {
      if (controller == null) {
        return;
      }
      cameraPreview = CameraPreview(controller);
      setState(() {});
      controller.startImageStream((image) {
        heartRate.value = image.planes.length.toString();
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (cameraPreview == null) {
      return const CircularProgressIndicator();
    } else {
      return Column(
        children: [
          SizedBox(
            height: 200,
            width: 200,
            child: cameraPreview,
          ),
          const SizedBox(height: 20),
          ValueListenableBuilder(
            valueListenable: heartRate,
            builder: (context, value, child) {
              return Text(
                  'plane| ${value}' + '\ntime |${DateTime.now().toString()}');
            },
          )
        ],
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class CameraFactory {
  CameraFactory._();
  static final i = CameraFactory._();

  Future<CameraController?> createCamera() async {
    try {
      var cameraDescription = await availableCameras();

      if (cameraDescription.isEmpty) {
        throw Exception('No cameras found');
      }

      var controller =
          CameraController(cameraDescription.first, ResolutionPreset.low);

      await controller.initialize();
      return controller;
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
