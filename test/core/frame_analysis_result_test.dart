import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_rate_detector/features/heart_rate/core/frame_analysis_result.dart';
import 'package:hear_rate_detector/features/heart_rate/core/rgb_values.dart';

void main() {
  group('FrameAnalysisResult', () {
    test('creates instance with all required fields', () {
      const rgbValues = RgbValues(red: 100, green: 150, blue: 200);
      final redJpeg = Uint8List.fromList([1, 2, 3]);
      final greenJpeg = Uint8List.fromList([4, 5, 6]);
      final blueJpeg = Uint8List.fromList([7, 8, 9]);

      final result = FrameAnalysisResult(
        rgbValues: rgbValues,
        redFilteredJpeg: redJpeg,
        greenFilteredJpeg: greenJpeg,
        blueFilteredJpeg: blueJpeg,
      );

      expect(result.rgbValues, equals(rgbValues));
      expect(result.redFilteredJpeg, equals(redJpeg));
      expect(result.greenFilteredJpeg, equals(greenJpeg));
      expect(result.blueFilteredJpeg, equals(blueJpeg));
    });

    test('stores RGB values correctly', () {
      const rgbValues = RgbValues(red: 180.5, green: 45.2, blue: 8.1);
      final result = FrameAnalysisResult(
        rgbValues: rgbValues,
        redFilteredJpeg: Uint8List(0),
        greenFilteredJpeg: Uint8List(0),
        blueFilteredJpeg: Uint8List(0),
      );

      expect(result.rgbValues.red, equals(180.5));
      expect(result.rgbValues.green, equals(45.2));
      expect(result.rgbValues.blue, equals(8.1));
    });

    test('handles empty JPEG arrays', () {
      final result = FrameAnalysisResult(
        rgbValues: const RgbValues(red: 0, green: 0, blue: 0),
        redFilteredJpeg: Uint8List(0),
        greenFilteredJpeg: Uint8List(0),
        blueFilteredJpeg: Uint8List(0),
      );

      expect(result.redFilteredJpeg.isEmpty, isTrue);
      expect(result.greenFilteredJpeg.isEmpty, isTrue);
      expect(result.blueFilteredJpeg.isEmpty, isTrue);
    });

    test('handles large JPEG arrays', () {
      final largeJpeg = Uint8List(10000); // 10KB
      final result = FrameAnalysisResult(
        rgbValues: const RgbValues(red: 128, green: 128, blue: 128),
        redFilteredJpeg: largeJpeg,
        greenFilteredJpeg: largeJpeg,
        blueFilteredJpeg: largeJpeg,
      );

      expect(result.redFilteredJpeg.length, equals(10000));
      expect(result.greenFilteredJpeg.length, equals(10000));
      expect(result.blueFilteredJpeg.length, equals(10000));
    });

    test('bundles data from same frame consistently', () {
      // Simulate real frame analysis
      const rgbValues = RgbValues(red: 150, green: 100, blue: 50);
      final redJpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF]); // JPEG header
      final greenJpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF]);
      final blueJpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF]);

      final result = FrameAnalysisResult(
        rgbValues: rgbValues,
        redFilteredJpeg: redJpeg,
        greenFilteredJpeg: greenJpeg,
        blueFilteredJpeg: blueJpeg,
      );

      // All data from same source frame
      expect(result.rgbValues, isNotNull);
      expect(result.redFilteredJpeg, isNotEmpty);
      expect(result.greenFilteredJpeg, isNotEmpty);
      expect(result.blueFilteredJpeg, isNotEmpty);
    });

    test('is immutable (const constructor)', () {
      const rgbValues = RgbValues(red: 100, green: 100, blue: 100);
      final result1 = FrameAnalysisResult(
        rgbValues: rgbValues,
        redFilteredJpeg: Uint8List(0),
        greenFilteredJpeg: Uint8List(0),
        blueFilteredJpeg: Uint8List(0),
      );

      // Cannot modify fields (compile-time immutability)
      expect(result1.rgbValues, equals(rgbValues));
    });

    test('represents typical analysis result', () {
      // Realistic values from optical heart rate detection
      const skinTone = RgbValues(red: 180.3, green: 120.5, blue: 95.2);
      final mockJpeg = Uint8List.fromList(List.generate(1000, (i) => i % 256));

      final result = FrameAnalysisResult(
        rgbValues: skinTone,
        redFilteredJpeg: mockJpeg,
        greenFilteredJpeg: mockJpeg,
        blueFilteredJpeg: mockJpeg,
      );

      expect(result.rgbValues.red, greaterThan(result.rgbValues.green));
      expect(result.rgbValues.green, greaterThan(result.rgbValues.blue));
      expect(result.redFilteredJpeg.isNotEmpty, isTrue);
    });
  });
}
