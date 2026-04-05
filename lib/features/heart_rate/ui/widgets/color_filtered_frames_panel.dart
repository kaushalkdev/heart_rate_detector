import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Displays three filtered camera frames showing only Red, Green, and Blue channels.
class ColorFilteredFramesPanel extends StatelessWidget {
  const ColorFilteredFramesPanel({
    super.key,
    required this.redFrame,
    required this.greenFrame,
    required this.blueFrame,
    this.frameSize = 100,
  });

  final ValueNotifier<Uint8List> redFrame;
  final ValueNotifier<Uint8List> greenFrame;
  final ValueNotifier<Uint8List> blueFrame;
  final double frameSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Color Channel Previews',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildChannelPreview('Red', redFrame, Colors.red),
              _buildChannelPreview('Green', greenFrame, Colors.green),
              _buildChannelPreview('Blue', blueFrame, Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChannelPreview(
    String label,
    ValueNotifier<Uint8List> frameBytes,
    Color labelColor,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<Uint8List>(
          valueListenable: frameBytes,
          builder: (context, data, child) {
            if (data.isEmpty) {
              return Container(
                width: frameSize,
                height: frameSize,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: frameSize,
                height: frameSize,
                // AnimatedSwitcher for smooth fade transitions between frames
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  child: Transform.rotate(
                    key: ValueKey<int>(data.hashCode),
                    // Rotate 90 degrees clockwise (π/2 radians)
                    angle: 1.5708, // 90 degrees in radians
                    child: Image.memory(
                      data,
                      fit: BoxFit.cover,
                      gaplessPlayback: true, // Prevents flicker
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
