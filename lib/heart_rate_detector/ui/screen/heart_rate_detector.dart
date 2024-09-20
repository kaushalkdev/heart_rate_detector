import 'dart:developer';
import 'dart:isolate';
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
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
  CameraController? cameraController;

  ValueNotifier<String> heartRate = ValueNotifier<String>('');
  ValueNotifier<Uint8List> byteSteam = ValueNotifier<Uint8List>(Uint8List(0));
  @override
  void initState() {
    cameraFactory.createCamera().then((controller) {
      if (controller == null) {
        return;
      }
      cameraController = controller;
      cameraPreview = CameraPreview(controller);
      setState(() {});
      controller.startImageStream((image) {
        heartRate.value =
            'plane : name ${image.format.group.name}| \nplane 1: ${image.planes.first.bytes.length} \nplane 2: ${image.planes[1].bytes.length} \nplane 3: ${image.planes[2].bytes.length}';
        byteSteam.value = rgbToJpeg(
            yuvToRgb(image.planes[0].bytes, image.planes[1].bytes,
                image.planes[2].bytes, image.width, image.height),
            image.width,
            image.height);
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
          ElevatedButton(
              onPressed: () async {
                var image = await cameraController?.takePicture();

                byteSteam.value = (await image?.readAsBytes())!;
                // log(byteSteam.value.toString());
                log(byteSteam.value[0].toString() +
                    " " +
                    byteSteam.value[1].toString());
              },
              child: Text("Take Image")),
          ValueListenableBuilder(
            valueListenable: byteSteam,
            builder: (context, byte, child) {
              return SizedBox(
                height: 200,
                width: 200,
                child: Image.memory(byte),
              );
            },
          ),
          ValueListenableBuilder(
            valueListenable: heartRate,
            builder: (context, value, child) {
              return Text('plane | ${value}');
            },
          )
        ],
      );
    }
  }

  // Convert RGB to JPEG
  Uint8List rgbToJpeg(Uint8List rgbBytes, int width, int height) {
    img.Image image = img.Image.fromBytes(width, height, rgbBytes);
    return Uint8List.fromList(img.encodeJpg(image));
  }

  Uint8List yuvToRgb(Uint8List yPlane, Uint8List uPlane, Uint8List vPlane,
      int width, int height) {
    final rgb = Uint8List(width * height * 3);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int yIndex = y * width + x;
        int uIndex = (y ~/ 2) * (width ~/ 2) + (x ~/ 2);
        int vIndex = (y ~/ 2) * (width ~/ 2) + (x ~/ 2);

        int yValue = yPlane[yIndex];
        int uValue = uPlane[uIndex] - 128;
        int vValue = vPlane[vIndex] - 128;

        int r = (yValue + 1.140 * vValue).round().clamp(0, 255);
        int g =
            (yValue - 0.395 * uValue - 0.581 * vValue).round().clamp(0, 255);
        int b = (yValue + 2.032 * uValue).round().clamp(0, 255);

        int rgbIndex = yIndex * 3;
        rgb[rgbIndex] = r;
        rgb[rgbIndex + 1] = g;
        rgb[rgbIndex + 2] = b;
      }
    }

    return rgb;
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
