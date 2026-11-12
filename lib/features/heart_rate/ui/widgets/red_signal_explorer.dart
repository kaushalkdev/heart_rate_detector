import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/red_signal.dart';
import '../../processing/interpolation/signal_interpolators.dart';
import '../red_signal_presenter.dart';
import 'red_signal_chart.dart';

/// All strategies receive the same snapshot, grid, gap policy and axis scale.
class RedSignalExplorer extends StatefulWidget {
  const RedSignalExplorer({
    super.key,
    required this.samples,
    required this.revision,
    required this.resetRevision,
    required this.presenter,
    required this.amplitudeRange,
    this.emptyMessage = 'Waiting for signal samples.',
  });
  final List<RedSignalSample> samples;
  final int revision;
  final int resetRevision;
  final RedSignalPresenter presenter;
  final SignalAmplitudeRange amplitudeRange;
  final String emptyMessage;
  @override
  State<RedSignalExplorer> createState() => _RedSignalExplorerState();
}

class _RedSignalExplorerState extends State<RedSignalExplorer> {
  List<RedSignalSample>? _pausedSamples;
  int? _pausedRevision;
  bool _showPoints = false;
  late List<RedSignalPresenter> _presenters;
  @override
  void initState() {
    super.initState();
    _createPresenters();
  }

  void _createPresenters() {
    _presenters = signalInterpolators
        .map(
          (algorithm) => RedSignalPresenter(
            interpolator: algorithm,
            gapFactor: widget.presenter.gapFactor,
            maxGridPoints: widget.presenter.maxGridPoints,
          ),
        )
        .toList();
  }

  @override
  void didUpdateWidget(RedSignalExplorer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetRevision != widget.resetRevision ||
        oldWidget.presenter != widget.presenter) {
      _pausedSamples = null;
      _pausedRevision = null;
      _createPresenters();
    }
  }

  @override
  Widget build(BuildContext context) {
    final samples = _pausedSamples ?? widget.samples;
    final revision = _pausedRevision ?? widget.revision;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Compare all three algorithms',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Wrap(
          spacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton.icon(
              onPressed: samples.isEmpty
                  ? null
                  : () => setState(() {
                      if (_pausedSamples == null) {
                        _pausedSamples = List.unmodifiable(samples);
                        _pausedRevision = revision;
                      } else {
                        _pausedSamples = null;
                        _pausedRevision = null;
                      }
                    }),
              icon: Icon(
                _pausedSamples == null ? Icons.pause : Icons.play_arrow,
              ),
              label: Text(
                _pausedSamples == null ? 'Pause display' : 'Resume display',
              ),
            ),
            FilterChip(
              label: const Text('Observed points'),
              selected: _showPoints,
              onSelected: (value) => setState(() => _showPoints = value),
            ),
          ],
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final sideBySide = constraints.maxWidth >= 1050;
            final width = sideBySide
                ? (constraints.maxWidth - 24) / 3
                : constraints.maxWidth;
            final displays = _presenters
                .map(
                  (presenter) => presenter.prepare(
                    samples,
                    revision: revision,
                    plotWidth: (width - 92).clamp(0, double.infinity),
                  ),
                )
                .toList();
            final values = displays
                .expand((d) => d.segments)
                .expand((s) => s)
                .map((s) => s.redIntensity)
                .where((value) => value.isFinite)
                .toList();
            var magnitude = 0.0;
            for (final value in values) {
              magnitude = math.max(magnitude, value.abs());
            }
            final range = SignalAmplitudeRange(
              maxMagnitude: values.isEmpty
                  ? widget.amplitudeRange.maxMagnitude
                  : math.max(.01, magnitude * 1.1),
            );
            final hasLine = displays.any(
              (d) => d.segments.any((s) => s.length >= 2),
            );
            final message = samples.isEmpty
                ? widget.emptyMessage
                : 'Collecting connected samples; isolated observations are shown as dots.';
            final charts = displays
                .map(
                  (display) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        display.algorithmId,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Last preparation: ${display.elapsedMicroseconds} us',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      RedSignalChart(
                        samples: samples,
                        segments: display.segments,
                        amplitudeRange: range,
                        showObservations: _showPoints,
                      ),
                    ],
                  ),
                )
                .toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!hasLine)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(message, key: const ValueKey('signal-status')),
                  ),
                const Text(
                  'Same 6-second window and automatic amplitude scale.',
                ),
                const SizedBox(height: 12),
                if (sideBySide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < charts.length; i++) ...[
                        if (i > 0) const SizedBox(width: 12),
                        Expanded(child: charts[i]),
                      ],
                    ],
                  )
                else ...[
                  for (final chart in charts) ...[
                    chart,
                    const SizedBox(height: 12),
                  ],
                ],
              ],
            );
          },
        ),
        const Text(
          'Preparation time excludes painting. Capture continues while the display is paused.',
          style: TextStyle(fontSize: 11),
        ),
      ],
    );
  }
}
