import 'package:flutter/material.dart';
import 'package:hear_rate_detector/features/heart_rate/default_heart_rate_scope.dart';
import 'package:permission_handler/permission_handler.dart';

/// Landing flow: request camera permission, then navigate to the capture screen.
class HeartRateHomePage extends StatefulWidget {
  const HeartRateHomePage({super.key, required this.title});

  final String title;

  @override
  State<HeartRateHomePage> createState() => _HeartRateHomePageState();
}

class _HeartRateHomePageState extends State<HeartRateHomePage> {
  PermissionStatus? _status;

  Future<PermissionStatus> _requestCameraPermission() async {
    return Permission.camera.request();
  }

  @override
  void initState() {
    super.initState();
    _requestCameraPermission().then((status) {
      _status = status;
      setState(() {});
    });
  }

  void _openDetector() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => createDefaultHeartRateDetectorPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Start heart rate capturing'),
            if (_status == PermissionStatus.permanentlyDenied)
              const Text(
                'Permission permanently denied, please enable it in settings',
              ),
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
        onPressed: _status == PermissionStatus.granted ? _openDetector : null,
        tooltip: 'Open camera',
        child: const Icon(Icons.camera),
      ),
    );
  }
}
