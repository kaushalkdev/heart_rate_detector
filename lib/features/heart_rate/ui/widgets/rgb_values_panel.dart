import 'package:flutter/material.dart';
import 'package:hear_rate_detector/features/heart_rate/core/rgb_values.dart';

/// Displays real-time RGB color channel values from camera frames.
class RgbValuesPanel extends StatelessWidget {
  const RgbValuesPanel({
    super.key,
    required this.rgbValues,
  });

  final ValueNotifier<RgbValues> rgbValues;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RgbValues>(
      valueListenable: rgbValues,
      builder: (context, values, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'RGB Channel Values',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildColorBar(
                'Red',
                values.red,
                Colors.red,
              ),
              const SizedBox(height: 12),
              _buildColorBar(
                'Green',
                values.green,
                Colors.green,
              ),
              const SizedBox(height: 12),
              _buildColorBar(
                'Blue',
                values.blue,
                Colors.blue,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColorBar(String label, double value, Color color) {
    final percentage = (value / 255.0).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              value.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 24,
                    width: double.infinity,
                    color: Colors.grey[200],
                  ),
                  Container(
                    height: 24,
                    width: percentage * constraints.maxWidth,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.6),
                          color,
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
