import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hear_rate_detector/features/heart_rate/core/red_signal.dart';
import 'package:hear_rate_detector/features/heart_rate/ui/red_signal_presenter.dart';
import 'package:hear_rate_detector/features/heart_rate/ui/widgets/red_signal_chart.dart';
import 'package:hear_rate_detector/features/heart_rate/ui/widgets/red_signal_explorer.dart';

void main() {
  testWidgets(
    'all three share data and scale; pause, resume and reset together',
    (tester) async {
      final presenter = RedSignalPresenter();
      final first = List.generate(
        7,
        (i) => RedSignalSample(
          timestamp: Duration(seconds: i),
          redIntensity: i.isEven ? 8 : 15,
        ),
      );
      Future<void> show(
        List<RedSignalSample> samples,
        int revision, {
        int reset = 0,
      }) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: RepaintBoundary(
                  key: const ValueKey('capture'),
                  child: RedSignalExplorer(
                    samples: samples,
                    revision: revision,
                    resetRevision: reset,
                    presenter: presenter,
                    emptyMessage: 'Waiting for stable capture.',
                    amplitudeRange: const SignalAmplitudeRange(
                      maxMagnitude: 1.44,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
      }

      List<RedSignalChart> charts() => tester
          .widgetList<RedSignalChart>(find.byType(RedSignalChart))
          .toList();
      await show(first, 1);
      expect(find.byType(RedSignalChart), findsNWidgets(3));
      for (final label in ['Linear', 'PCHIP', 'Natural cubic']) {
        expect(find.text(label), findsOneWidget);
      }
      final scale = charts().first.amplitudeRange!.maxMagnitude;
      expect(scale, greaterThan(15));
      for (final chart in charts()) {
        expect(chart.samples, same(first));
        expect(chart.amplitudeRange!.maxMagnitude, scale);
        expect(chart.segments!.single.length, greaterThan(first.length));
      }
      // Regression: observations entirely outside the old fixed range still paint red pixels.
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('capture')),
      );
      final pixels = (await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        image.dispose();
        return bytes;
      }))!;
      final color = Theme.of(tester.element(find.byType(RedSignalChart).first))
          .colorScheme
          .error
          .toARGB32();
      var redPixels = 0;
      for (var i = 0; i < pixels.lengthInBytes; i += 4) {
        if (pixels.getUint8(i) == ((color >> 16) & 255) &&
            pixels.getUint8(i + 1) == ((color >> 8) & 255) &&
            pixels.getUint8(i + 2) == (color & 255)) {
          redPixels++;
        }
      }
      expect(redPixels, greaterThan(100));
      await tester.tap(find.text('Observed points'));
      await tester.pump();
      expect(charts().every((c) => c.showObservations), isTrue);
      await tester.tap(find.text('Pause display'));
      await tester.pump();
      final next = [
        ...first,
        const RedSignalSample(
          timestamp: Duration(seconds: 7),
          redIntensity: 20,
        ),
      ];
      await show(next, 2);
      expect(charts().every((c) => c.samples.length == 7), isTrue);
      await tester.tap(find.text('Resume display'));
      await tester.pump();
      expect(charts().every((c) => c.samples.length == 8), isTrue);
      await tester.tap(find.text('Pause display'));
      await tester.pump();
      await show([], 3, reset: 1);
      expect(find.text('Waiting for stable capture.'), findsOneWidget);
      expect(charts().every((c) => c.samples.isEmpty), isTrue);
      expect(find.text('Pause display'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('wide layout and singleton samples remain visible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RedSignalExplorer(
            samples: const [
              RedSignalSample(timestamp: Duration.zero, redIntensity: 3),
            ],
            revision: 1,
            resetRevision: 0,
            presenter: RedSignalPresenter(),
            amplitudeRange: const SignalAmplitudeRange(maxMagnitude: 1.44),
          ),
        ),
      ),
    );
    final finder = find.byType(RedSignalChart);
    expect(finder, findsNWidgets(3));
    expect(
      tester.getTopLeft(finder.at(0)).dy,
      tester.getTopLeft(finder.at(2)).dy,
    );
    expect(find.textContaining('isolated observations'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
