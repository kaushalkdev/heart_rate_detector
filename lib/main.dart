import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PermissionStatus? _status;

  Future<PermissionStatus> _requestCameraPermission() async {
    return await Permission.camera.request();
  }

  @override
  void initState() {
    _requestCameraPermission().then((status) {
      _status = status;
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Start heart rate capturing',
            ),
            if (_status == PermissionStatus.permanentlyDenied)
              const Text(
                  'Permission permanently denied, please enable it in settings'),
            if (_status == PermissionStatus.denied)
              ElevatedButton(
                onPressed: () async {
                  _status = await _requestCameraPermission();
                  setState(() {});
                },
                child: const Text('Request Camera permission'),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: !(_status == PermissionStatus.granted)
            ? null
            : () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DetectionScreen(),
                    ));
              },
        tooltip: 'Increment',
        child: const Icon(Icons.camera),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class DetectionScreen extends StatefulWidget {
  const DetectionScreen({super.key});

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
  CameraPreview? _cameraPreview;
  CameraFactory cameraFactory = CameraFactory.i;

  @override
  void initState() {
    cameraFactory.createCamera().then((cameraPreview) {
      _cameraPreview = cameraPreview;
      setState(() {});
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return (_cameraPreview == null)
        ? const SizedBox(height: 100, width: 100, child: Placeholder())
        : SizedBox(
            height: 100,
            width: 100,
            child: _cameraPreview,
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
    var cameraDescription = await availableCameras();

    if (cameraDescription.isEmpty) {
      throw Exception('No cameras found');
    }

    _controller =
        CameraController(cameraDescription.first, ResolutionPreset.high);

    return CameraPreview(_controller!);
  }

  void disposeCamera() {
    _controller?.dispose();
  }
}
