import 'package:flutter_test/flutter_test.dart';
import 'package:hear_rate_detector/features/heart_rate/core/rgb_values.dart';

void main() {
  group('RgbValues', () {
    test('creates instance with valid values', () {
      const rgb = RgbValues(red: 128.5, green: 64.3, blue: 200.7);

      expect(rgb.red, equals(128.5));
      expect(rgb.green, equals(64.3));
      expect(rgb.blue, equals(200.7));
    });

    test('handles minimum values (0)', () {
      const rgb = RgbValues(red: 0, green: 0, blue: 0);

      expect(rgb.red, equals(0));
      expect(rgb.green, equals(0));
      expect(rgb.blue, equals(0));
    });

    test('handles maximum values (255)', () {
      const rgb = RgbValues(red: 255, green: 255, blue: 255);

      expect(rgb.red, equals(255));
      expect(rgb.green, equals(255));
      expect(rgb.blue, equals(255));
    });

    test('supports fractional values', () {
      const rgb = RgbValues(red: 127.5, green: 64.25, blue: 200.75);

      expect(rgb.red, equals(127.5));
      expect(rgb.green, equals(64.25));
      expect(rgb.blue, equals(200.75));
    });

    test('toString formats correctly with one decimal', () {
      const rgb = RgbValues(red: 180.5, green: 45.2, blue: 8.1);

      expect(rgb.toString(), equals('R: 180.5, G: 45.2, B: 8.1'));
    });

    test('toString handles whole numbers', () {
      const rgb = RgbValues(red: 100, green: 150, blue: 200);

      expect(rgb.toString(), equals('R: 100.0, G: 150.0, B: 200.0'));
    });

    test('toString handles zero values', () {
      const rgb = RgbValues(red: 0, green: 0, blue: 0);

      expect(rgb.toString(), equals('R: 0.0, G: 0.0, B: 0.0'));
    });

    test('toString handles max values', () {
      const rgb = RgbValues(red: 255, green: 255, blue: 255);

      expect(rgb.toString(), equals('R: 255.0, G: 255.0, B: 255.0'));
    });

    test('is immutable (const constructor)', () {
      const rgb1 = RgbValues(red: 100, green: 100, blue: 100);
      const rgb2 = RgbValues(red: 100, green: 100, blue: 100);

      // Same values should be equal (value equality)
      expect(rgb1, equals(rgb2));
    });

    test('different values are not equal', () {
      const rgb1 = RgbValues(red: 100, green: 100, blue: 100);
      const rgb2 = RgbValues(red: 100, green: 100, blue: 101);

      expect(rgb1, isNot(equals(rgb2)));
    });

    test('represents typical skin tone values', () {
      // Realistic values for optical heart rate detection
      const skinTone = RgbValues(red: 180.3, green: 120.5, blue: 95.2);

      expect(skinTone.red, greaterThan(skinTone.green));
      expect(skinTone.green, greaterThan(skinTone.blue));
    });

    test('represents red-dominant frame', () {
      const redFrame = RgbValues(red: 200, green: 50, blue: 50);

      expect(redFrame.red, greaterThan(redFrame.green));
      expect(redFrame.red, greaterThan(redFrame.blue));
    });

    test('represents green-dominant frame', () {
      const greenFrame = RgbValues(red: 50, green: 200, blue: 50);

      expect(greenFrame.green, greaterThan(greenFrame.red));
      expect(greenFrame.green, greaterThan(greenFrame.blue));
    });

    test('represents blue-dominant frame', () {
      const blueFrame = RgbValues(red: 50, green: 50, blue: 200);

      expect(blueFrame.blue, greaterThan(blueFrame.red));
      expect(blueFrame.blue, greaterThan(blueFrame.green));
    });

    test('handles precision correctly', () {
      const rgb = RgbValues(red: 127.123, green: 64.456, blue: 200.789);

      // Values stored with full precision
      expect(rgb.red, equals(127.123));
      expect(rgb.green, equals(64.456));
      expect(rgb.blue, equals(200.789));

      // But toString shows only 1 decimal
      expect(rgb.toString(), equals('R: 127.1, G: 64.5, B: 200.8'));
    });
  });
}
