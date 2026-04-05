import 'package:flutter/material.dart';

/// Live camera preview only; keeps layout separate from session types.
class LivePreviewPanel extends StatelessWidget {
  const LivePreviewPanel({
    super.key,
    required this.preview,
    this.size = 200,
  });

  final Widget preview;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: preview,
    );
  }
}
