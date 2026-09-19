import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hear_rate_detector/features/heart_rate/core/red_signal.dart';

class RedSignalChart extends StatelessWidget {
  const RedSignalChart({super.key, required this.samples, this.amplitudeRange});

  final List<RedSignalSample> samples;
  final SignalAmplitudeRange? amplitudeRange;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Live graph of filtered red intensity over elapsed seconds',
      child: SizedBox(
        height: 240,
        width: double.infinity,
        child: CustomPaint(
          painter: _RedSignalPainter(
            samples,
            Theme.of(context).colorScheme,
            amplitudeRange,
          ),
        ),
      ),
    );
  }
}

class _RedSignalPainter extends CustomPainter {
  _RedSignalPainter(this.samples, this.colors, this.amplitudeRange);

  static const _visibleWindow = Duration(seconds: 6);

  final List<RedSignalSample> samples;
  final ColorScheme colors;
  final SignalAmplitudeRange? amplitudeRange;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2) return;

    const left = 38.0;
    const top = 16.0;
    const right = 54.0;
    const bottom = 28.0;
    final plot = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    final gridPaint = Paint()
      ..color = colors.outlineVariant
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final y = plot.top + plot.height * i / 4;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
    }
    canvas.drawLine(
      Offset(plot.left, plot.center.dy),
      Offset(plot.right, plot.center.dy),
      Paint()
        ..color = colors.onSurfaceVariant
        ..strokeWidth = 1.5,
    );

    _label(canvas, '6s', Offset(plot.left - 8, plot.bottom + 4));
    _label(canvas, '0s', Offset(plot.right - 8, plot.bottom + 4));

    final newestMicros = samples.last.timestamp.inMicroseconds;
    final windowMicros = _visibleWindow.inMicroseconds;
    final range = amplitudeRange;
    var maxMagnitude = range?.maxMagnitude ?? 0.5;
    if (range == null) {
      for (final sample in samples) {
        maxMagnitude = math.max(maxMagnitude, sample.redIntensity.abs());
      }
    }

    final path = Path();
    var started = false;
    for (final sample in samples) {
      if (!sample.redIntensity.isFinite) {
        started = false;
        continue;
      }

      final age = newestMicros - sample.timestamp.inMicroseconds;
      final x = plot.right - (age / windowMicros) * plot.width;
      final normalized = sample.redIntensity / maxMagnitude;
      final y = plot.center.dy - normalized * plot.height / 2;
      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.save();
    canvas.clipRect(plot);
    canvas.drawPath(
      path,
      Paint()
        ..color = colors.error
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();

    _label(
      canvas,
      '+${maxMagnitude.toStringAsFixed(2)}',
      Offset(plot.right + 6, plot.top - 2),
    );
    _label(
      canvas,
      '-${maxMagnitude.toStringAsFixed(2)}',
      Offset(plot.right + 6, plot.bottom - 14),
    );
  }

  void _label(Canvas canvas, String text, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_RedSignalPainter oldDelegate) =>
      oldDelegate.samples != samples ||
      oldDelegate.colors != colors ||
      oldDelegate.amplitudeRange != amplitudeRange;
}
