import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hear_rate_detector/features/heart_rate/core/red_signal.dart';

class RedSignalChart extends StatelessWidget {
  const RedSignalChart({super.key, required this.samples});

  final List<RedSignalSample> samples;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Live graph of red signal difference over elapsed seconds',
      child: SizedBox(
        height: 240,
        width: double.infinity,
        child: CustomPaint(
          painter: _RedSignalPainter(samples, Theme.of(context).colorScheme),
        ),
      ),
    );
  }
}

class _RedSignalPainter extends CustomPainter {
  _RedSignalPainter(this.samples, this.colors);

  final List<RedSignalSample> samples;
  final ColorScheme colors;

  @override
  void paint(Canvas canvas, Size size) {
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

    _label(canvas, '15s', Offset(plot.left - 8, plot.bottom + 4));
    _label(canvas, '0s', Offset(plot.right - 8, plot.bottom + 4));
    _label(canvas, 'Red Δ', Offset(plot.right + 8, plot.top - 2));

    if (samples.length < 2) {
      _label(
        canvas,
        'Waiting for signal…',
        Offset(plot.center.dx - 55, plot.center.dy - 10),
      );
      return;
    }

    final newestMicros = samples.last.timestamp.inMicroseconds;
    const windowMicros = 15 * Duration.microsecondsPerSecond;
    var maxMagnitude = 0.5;
    for (final sample in samples) {
      maxMagnitude = math.max(maxMagnitude, sample.difference.abs());
    }

    final path = Path();
    var started = false;
    for (final sample in samples) {
      final age = newestMicros - sample.timestamp.inMicroseconds;
      final x = plot.right - (age / windowMicros) * plot.width;
      final normalized = (sample.difference / maxMagnitude).clamp(-1.0, 1.0);
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
      '+${maxMagnitude.toStringAsFixed(1)}',
      Offset(plot.right + 6, plot.top - 2),
    );
    _label(
      canvas,
      '−${maxMagnitude.toStringAsFixed(1)}',
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
      oldDelegate.samples != samples || oldDelegate.colors != colors;
}
