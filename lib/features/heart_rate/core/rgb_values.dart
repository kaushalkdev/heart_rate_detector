/// Represents the average RGB color values from a camera frame.
/// Values range from 0-255 for each channel.
class RgbValues {
  const RgbValues({
    required this.red,
    required this.green,
    required this.blue,
  });

  final double red;
  final double green;
  final double blue;

  @override
  String toString() => 'R: ${red.toStringAsFixed(1)}, '
      'G: ${green.toStringAsFixed(1)}, '
      'B: ${blue.toStringAsFixed(1)}';
}
