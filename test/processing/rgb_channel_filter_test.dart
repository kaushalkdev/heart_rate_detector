import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hear_rate_detector/features/heart_rate/processing/rgb_channel_filter.dart';

void main() {
  group('RgbChannelFilter', () {
    late RgbChannelFilter filter;

    setUp(() {
      filter = RgbChannelFilter();
    });

    group('filterRedChannel', () {
      test('keeps red, zeros green and blue', () {
        final rgbData = Uint8List.fromList([128, 64, 192]);

        final filtered = filter.filterRedChannel(rgbData);

        expect(filtered[0], equals(128)); // Red kept
        expect(filtered[1], equals(0)); // Green zeroed
        expect(filtered[2], equals(0)); // Blue zeroed
      });

      test('filters multiple pixels correctly', () {
        final rgbData = Uint8List.fromList([
          100, 50, 25,
          200, 150, 75,
          150, 100, 50,
        ]);

        final filtered = filter.filterRedChannel(rgbData);

        expect(filtered, equals(Uint8List.fromList([
          100, 0, 0,
          200, 0, 0,
          150, 0, 0,
        ])));
      });

      test('handles all zeros', () {
        final rgbData = Uint8List.fromList([0, 0, 0, 0, 0, 0]);

        final filtered = filter.filterRedChannel(rgbData);

        expect(filtered, equals(Uint8List.fromList([0, 0, 0, 0, 0, 0])));
      });

      test('preserves max red values', () {
        final rgbData = Uint8List.fromList([255, 255, 255]);

        final filtered = filter.filterRedChannel(rgbData);

        expect(filtered[0], equals(255));
        expect(filtered[1], equals(0));
        expect(filtered[2], equals(0));
      });
    });

    group('filterGreenChannel', () {
      test('keeps green, zeros red and blue', () {
        final rgbData = Uint8List.fromList([128, 64, 192]);

        final filtered = filter.filterGreenChannel(rgbData);

        expect(filtered[0], equals(0)); // Red zeroed
        expect(filtered[1], equals(64)); // Green kept
        expect(filtered[2], equals(0)); // Blue zeroed
      });

      test('filters multiple pixels correctly', () {
        final rgbData = Uint8List.fromList([
          100, 50, 25,
          200, 150, 75,
          150, 100, 50,
        ]);

        final filtered = filter.filterGreenChannel(rgbData);

        expect(filtered, equals(Uint8List.fromList([
          0, 50, 0,
          0, 150, 0,
          0, 100, 0,
        ])));
      });

      test('preserves max green values', () {
        final rgbData = Uint8List.fromList([255, 255, 255]);

        final filtered = filter.filterGreenChannel(rgbData);

        expect(filtered[0], equals(0));
        expect(filtered[1], equals(255));
        expect(filtered[2], equals(0));
      });
    });

    group('filterBlueChannel', () {
      test('keeps blue, zeros red and green', () {
        final rgbData = Uint8List.fromList([128, 64, 192]);

        final filtered = filter.filterBlueChannel(rgbData);

        expect(filtered[0], equals(0)); // Red zeroed
        expect(filtered[1], equals(0)); // Green zeroed
        expect(filtered[2], equals(192)); // Blue kept
      });

      test('filters multiple pixels correctly', () {
        final rgbData = Uint8List.fromList([
          100, 50, 25,
          200, 150, 75,
          150, 100, 50,
        ]);

        final filtered = filter.filterBlueChannel(rgbData);

        expect(filtered, equals(Uint8List.fromList([
          0, 0, 25,
          0, 0, 75,
          0, 0, 50,
        ])));
      });

      test('preserves max blue values', () {
        final rgbData = Uint8List.fromList([255, 255, 255]);

        final filtered = filter.filterBlueChannel(rgbData);

        expect(filtered[0], equals(0));
        expect(filtered[1], equals(0));
        expect(filtered[2], equals(255));
      });
    });

    group('All filters', () {
      test('do not modify original data', () {
        final original = Uint8List.fromList([128, 64, 192]);
        final originalCopy = Uint8List.fromList([128, 64, 192]);

        filter.filterRedChannel(original);
        filter.filterGreenChannel(original);
        filter.filterBlueChannel(original);

        expect(original, equals(originalCopy));
      });

      test('return new arrays (not modifying in place)', () {
        final rgbData = Uint8List.fromList([128, 64, 192]);

        final red = filter.filterRedChannel(rgbData);
        final green = filter.filterGreenChannel(rgbData);
        final blue = filter.filterBlueChannel(rgbData);

        // All should be different instances
        expect(identical(red, rgbData), isFalse);
        expect(identical(green, rgbData), isFalse);
        expect(identical(blue, rgbData), isFalse);
        expect(identical(red, green), isFalse);
      });

      test('sum of filtered values equals original for each pixel', () {
        final rgbData = Uint8List.fromList([
          128, 64, 192,
          100, 150, 200,
        ]);

        final red = filter.filterRedChannel(rgbData);
        final green = filter.filterGreenChannel(rgbData);
        final blue = filter.filterBlueChannel(rgbData);

        // For each pixel position, sum equals original
        for (var i = 0; i < rgbData.length; i++) {
          expect(red[i] + green[i] + blue[i], equals(rgbData[i]));
        }
      });

      test('performance: filters large frame quickly', () {
        final pixelCount = 320 * 240;
        final rgbData = Uint8List(pixelCount * 3);

        final stopwatch = Stopwatch()..start();
        filter.filterRedChannel(rgbData);
        filter.filterGreenChannel(rgbData);
        filter.filterBlueChannel(rgbData);
        stopwatch.stop();

        // All 3 filters should complete in under 50ms
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });
    });
  });
}
