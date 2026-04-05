import 'package:flutter/material.dart';
import 'package:hear_rate_detector/features/heart_rate/heart_rate_flow.dart';

class HeartRateApp extends StatelessWidget {
  const HeartRateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Heart Rate Detector',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HeartRateHomePage(title: 'Heart Rate Detector'),
    );
  }
}
