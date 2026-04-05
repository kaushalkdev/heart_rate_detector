/// One scalar sample in the optical (e.g. PPG) signal domain, independent of camera planes.
class OpticalSignalSample {
  const OpticalSignalSample({
    required this.t,
    required this.value,
  });

  final DateTime t;
  final double value;
}
