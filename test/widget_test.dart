import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_rate_detector/app/app.dart';
import 'package:hear_rate_detector/features/heart_rate/core/rgb_values.dart';
import 'package:hear_rate_detector/features/heart_rate/ui/widgets/rgb_values_panel.dart';
import 'package:hear_rate_detector/features/heart_rate/ui/widgets/color_filtered_frames_panel.dart';

void main() {
  group('App Tests', () {
    testWidgets('App launches and shows home page', (WidgetTester tester) async {
      await tester.pumpWidget(const HeartRateApp());

      expect(find.text('Start heart rate capturing'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('Home page has camera button', (WidgetTester tester) async {
      await tester.pumpWidget(const HeartRateApp());
      await tester.pump();

      // Should show camera floating action button
      expect(find.byIcon(Icons.camera), findsOneWidget);
    });
  });

  group('RGB Values Panel Tests', () {
    testWidgets('Displays RGB values correctly', (WidgetTester tester) async {
      final rgbValues = ValueNotifier<RgbValues>(
        const RgbValues(red: 180.5, green: 45.2, blue: 8.1),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RgbValuesPanel(rgbValues: rgbValues),
          ),
        ),
      );

      expect(find.text('RGB Channel Values'), findsOneWidget);
      expect(find.text('Red'), findsOneWidget);
      expect(find.text('Green'), findsOneWidget);
      expect(find.text('Blue'), findsOneWidget);
      expect(find.text('180.5'), findsOneWidget);
      expect(find.text('45.2'), findsOneWidget);
      expect(find.text('8.1'), findsOneWidget);
    });

    testWidgets('Updates when RGB values change', (WidgetTester tester) async {
      final rgbValues = ValueNotifier<RgbValues>(
        const RgbValues(red: 100.0, green: 100.0, blue: 100.0),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RgbValuesPanel(rgbValues: rgbValues),
          ),
        ),
      );

      expect(find.text('100.0'), findsNWidgets(3));

      // Change values
      rgbValues.value = const RgbValues(red: 200.0, green: 150.0, blue: 50.0);
      await tester.pump();

      expect(find.text('200.0'), findsOneWidget);
      expect(find.text('150.0'), findsOneWidget);
      expect(find.text('50.0'), findsOneWidget);
      expect(find.text('100.0'), findsNothing);
    });
  });

  group('Color Filtered Frames Panel Tests', () {
    testWidgets('Shows all three color channels', (WidgetTester tester) async {
      final redFrame = ValueNotifier<Uint8List>(Uint8List(0));
      final greenFrame = ValueNotifier<Uint8List>(Uint8List(0));
      final blueFrame = ValueNotifier<Uint8List>(Uint8List(0));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ColorFilteredFramesPanel(
              redFrame: redFrame,
              greenFrame: greenFrame,
              blueFrame: blueFrame,
            ),
          ),
        ),
      );

      expect(find.text('Color Channel Previews'), findsOneWidget);
      expect(find.text('Red'), findsOneWidget);
      expect(find.text('Green'), findsOneWidget);
      expect(find.text('Blue'), findsOneWidget);

      // Should show loading indicators when frames are empty
      expect(find.byType(CircularProgressIndicator), findsNWidgets(3));
    });
  });

  group('RgbValues Model Tests', () {
    test('Creates RgbValues with correct values', () {
      const rgb = RgbValues(red: 255.0, green: 128.0, blue: 0.0);

      expect(rgb.red, equals(255.0));
      expect(rgb.green, equals(128.0));
      expect(rgb.blue, equals(0.0));
    });

    test('toString formats correctly', () {
      const rgb = RgbValues(red: 180.5, green: 45.2, blue: 8.1);

      expect(rgb.toString(), equals('R: 180.5, G: 45.2, B: 8.1'));
    });
  });
}
