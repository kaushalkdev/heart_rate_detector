import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_rate_detector/features/heart_rate/ui/widgets/color_filtered_frames_panel.dart';

void main() {
  group('ColorFilteredFramesPanel Widget Tests', () {
    testWidgets('displays panel title', (WidgetTester tester) async {
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
    });

    testWidgets('displays all three channel labels', (WidgetTester tester) async {
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

      expect(find.text('Red'), findsOneWidget);
      expect(find.text('Green'), findsOneWidget);
      expect(find.text('Blue'), findsOneWidget);
    });

    testWidgets('shows loading indicators when frames are empty', (WidgetTester tester) async {
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

      expect(find.byType(CircularProgressIndicator), findsNWidgets(3));
    });

    testWidgets('uses ValueListenableBuilder for updates', (WidgetTester tester) async {
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

      // Should use ValueListenableBuilder for each frame
      expect(find.byType(ValueListenableBuilder<Uint8List>), findsNWidgets(3));
    });

    testWidgets('displays loading state correctly', (WidgetTester tester) async {
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

      // Empty frames should show loading indicators
      expect(find.byType(CircularProgressIndicator), findsNWidgets(3));

      // Labels should still be visible
      expect(find.text('Red'), findsOneWidget);
      expect(find.text('Green'), findsOneWidget);
      expect(find.text('Blue'), findsOneWidget);
    });

    testWidgets('respects custom frame size parameter', (WidgetTester tester) async {
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
              frameSize: 150, // Custom size
            ),
          ),
        ),
      );

      // Panel should render without errors
      expect(find.byType(ColorFilteredFramesPanel), findsOneWidget);
    });
  });
}
