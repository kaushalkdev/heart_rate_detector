import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_rate_detector/features/heart_rate/processing/rgb_analyzer.dart';

void main() {
  group('RgbAnalyzer', () {
    late RgbAnalyzer analyzer;

    setUp(() {
      analyzer = RgbAnalyzer();
    });

    test('analyzes single pixel correctly', () {
      // RGB data: [R, G, B]
      final rgbData = Uint8List.fromList([128, 64, 192]);

      final result = analyzer.analyzeFrame(rgbData);

      expect(result.red, equals(128.0));
      expect(result.green, equals(64.0));
      expect(result.blue, equals(192.0));
    });

    test('calculates average of multiple pixels', () {
      // 3 pixels: (100,50,25), (200,150,75), (150,100,50)
      final rgbData = Uint8List.fromList([
        100, 50, 25, // Pixel 1
        200, 150, 75, // Pixel 2
        150, 100, 50, // Pixel 3
      ]);

      final result = analyzer.analyzeFrame(rgbData);

      // Average: (100+200+150)/3 = 150, (50+150+100)/3 = 100, (25+75+50)/3 = 50
      expect(result.red, equals(150.0));
      expect(result.green, equals(100.0));
      expect(result.blue, equals(50.0));
    });

    test('handles all black pixels', () {
      final rgbData = Uint8List.fromList([0, 0, 0, 0, 0, 0, 0, 0, 0]);

      final result = analyzer.analyzeFrame(rgbData);

      expect(result.red, equals(0.0));
      expect(result.green, equals(0.0));
      expect(result.blue, equals(0.0));
    });

    test('handles all white pixels', () {
      final rgbData = Uint8List.fromList([255, 255, 255, 255, 255, 255]);

      final result = analyzer.analyzeFrame(rgbData);

      expect(result.red, equals(255.0));
      expect(result.green, equals(255.0));
      expect(result.blue, equals(255.0));
    });

    test('handles empty frame', () {
      final rgbData = Uint8List(0);

      final result = analyzer.analyzeFrame(rgbData);

      // Should return zeros for empty frame
      expect(result.red, equals(0.0));
      expect(result.green, equals(0.0));
      expect(result.blue, equals(0.0));
    });

    test('calculates fractional averages correctly', () {
      // 2 pixels: (100,100,100), (101,101,101)
      final rgbData = Uint8List.fromList([
        100, 100, 100,
        101, 101, 101,
      ]);

      final result = analyzer.analyzeFrame(rgbData);

      // Average: 100.5 for each channel
      expect(result.red, equals(100.5));
      expect(result.green, equals(100.5));
      expect(result.blue, equals(100.5));
    });

    test('handles red-dominant frame', () {
      // Multiple pixels with high red values
      final rgbData = Uint8List.fromList([
        200, 50, 50,
        220, 60, 55,
        210, 55, 52,
      ]);

      final result = analyzer.analyzeFrame(rgbData);

      expect(result.red, greaterThan(result.green));
      expect(result.red, greaterThan(result.blue));
    });

    test('handles green-dominant frame', () {
      final rgbData = Uint8List.fromList([
        50, 200, 50,
        60, 220, 55,
        55, 210, 52,
      ]);

      final result = analyzer.analyzeFrame(rgbData);

      expect(result.green, greaterThan(result.red));
      expect(result.green, greaterThan(result.blue));
    });

    test('handles blue-dominant frame', () {
      final rgbData = Uint8List.fromList([
        50, 50, 200,
        60, 55, 220,
        55, 52, 210,
      ]);

      final result = analyzer.analyzeFrame(rgbData);

      expect(result.blue, greaterThan(result.red));
      expect(result.blue, greaterThan(result.green));
    });

    test('handles typical skin tone values', () {
      // Simulate skin under camera (red-dominant)
      final rgbData = Uint8List.fromList([
        180, 120, 95,
        185, 125, 100,
        175, 115, 90,
      ]);

      final result = analyzer.analyzeFrame(rgbData);

      // Skin typically: red > green > blue
      expect(result.red, greaterThan(result.green));
      expect(result.green, greaterThan(result.blue));
      expect(result.red, inInclusiveRange(170.0, 190.0));
    });

    test('handles large frame (320x240 pixels)', () {
      // 320x240 = 76,800 pixels = 230,400 bytes
      final pixelCount = 320 * 240;
      final rgbData = Uint8List(pixelCount * 3);

      // Fill with gradient: red increases, green/blue constant
      for (var i = 0; i < pixelCount; i++) {
        rgbData[i * 3] = (i % 256); // Red varies
        rgbData[i * 3 + 1] = 128; // Green constant
        rgbData[i * 3 + 2] = 64; // Blue constant
      }

      final result = analyzer.analyzeFrame(rgbData);

      // Average of 0-255 gradient ≈ 127.5
      expect(result.red, closeTo(127.5, 1.0));
      expect(result.green, equals(128.0));
      expect(result.blue, equals(64.0));
    });

    test('performance: processes frame quickly', () {
      final pixelCount = 320 * 240;
      final rgbData = Uint8List(pixelCount * 3);
      
      final stopwatch = Stopwatch()..start();
      analyzer.analyzeFrame(rgbData);
      stopwatch.stop();

      // Should complete in under 10ms (typically ~2ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(10));
    });
  });
}
