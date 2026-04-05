import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_rate_detector/features/heart_rate/core/rgb_values.dart';
import 'package:hear_rate_detector/features/heart_rate/ui/widgets/rgb_values_panel.dart';

void main() {
  group('RgbValuesPanel Widget Tests', () {
    testWidgets('displays panel title', (WidgetTester tester) async {
      final rgbValues = ValueNotifier<RgbValues>(
        const RgbValues(red: 0, green: 0, blue: 0),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RgbValuesPanel(rgbValues: rgbValues),
          ),
        ),
      );

      expect(find.text('RGB Channel Values'), findsOneWidget);
    });

    testWidgets('displays all three color labels', (WidgetTester tester) async {
      final rgbValues = ValueNotifier<RgbValues>(
        const RgbValues(red: 100, green: 100, blue: 100),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RgbValuesPanel(rgbValues: rgbValues),
          ),
        ),
      );

      expect(find.text('Red'), findsOneWidget);
      expect(find.text('Green'), findsOneWidget);
      expect(find.text('Blue'), findsOneWidget);
    });

    testWidgets('displays RGB values with one decimal place', (WidgetTester tester) async {
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

      expect(find.text('180.5'), findsOneWidget);
      expect(find.text('45.2'), findsOneWidget);
      expect(find.text('8.1'), findsOneWidget);
    });

    testWidgets('updates values when notifier changes', (WidgetTester tester) async {
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
      rgbValues.value = const RgbValues(red: 200.5, green: 150.3, blue: 50.7);
      await tester.pump();

      expect(find.text('200.5'), findsOneWidget);
      expect(find.text('150.3'), findsOneWidget);
      expect(find.text('50.7'), findsOneWidget);
      expect(find.text('100.0'), findsNothing);
    });

    testWidgets('displays zero values correctly', (WidgetTester tester) async {
      final rgbValues = ValueNotifier<RgbValues>(
        const RgbValues(red: 0, green: 0, blue: 0),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RgbValuesPanel(rgbValues: rgbValues),
          ),
        ),
      );

      expect(find.text('0.0'), findsNWidgets(3));
    });

    testWidgets('displays maximum values correctly', (WidgetTester tester) async {
      final rgbValues = ValueNotifier<RgbValues>(
        const RgbValues(red: 255, green: 255, blue: 255),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RgbValuesPanel(rgbValues: rgbValues),
          ),
        ),
      );

      expect(find.text('255.0'), findsNWidgets(3));
    });

    testWidgets('has white background container', (WidgetTester tester) async {
      final rgbValues = ValueNotifier<RgbValues>(
        const RgbValues(red: 128, green: 128, blue: 128),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RgbValuesPanel(rgbValues: rgbValues),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('RGB Channel Values'),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.white));
      expect(decoration.borderRadius, isNotNull);
      expect(decoration.boxShadow, isNotNull);
    });

    testWidgets('responds to rapid value changes', (WidgetTester tester) async {
      final rgbValues = ValueNotifier<RgbValues>(
        const RgbValues(red: 100, green: 100, blue: 100),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RgbValuesPanel(rgbValues: rgbValues),
          ),
        ),
      );

      // Simulate rapid frame updates
      for (var i = 0; i < 10; i++) {
        rgbValues.value = RgbValues(
          red: 100 + i * 10.0,
          green: 100 + i * 5.0,
          blue: 100 - i * 5.0,
        );
        await tester.pump();
      }

      // Should show latest values
      expect(find.text('190.0'), findsOneWidget); // 100 + 9*10
      expect(find.text('145.0'), findsOneWidget); // 100 + 9*5
      expect(find.text('55.0'), findsOneWidget); // 100 - 9*5
    });

    testWidgets('uses ValueListenableBuilder for efficient updates', (WidgetTester tester) async {
      final rgbValues = ValueNotifier<RgbValues>(
        const RgbValues(red: 128, green: 128, blue: 128),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RgbValuesPanel(rgbValues: rgbValues),
          ),
        ),
      );

      expect(find.byType(ValueListenableBuilder<RgbValues>), findsOneWidget);
    });
  });
}
