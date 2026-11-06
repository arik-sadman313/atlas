class InkPoint {
  final double x;
  final double y;
  final double pressure; // Normalized 0.0 to 1.0 (default 0.5)
  final double tiltAzimuth; // Radians -pi to pi (default 0.0)
  final double tiltAltitude; // Radians 0.0 to pi/2 (default pi/2)
  final int timeOffsetMs; // Milliseconds from stroke start

  const InkPoint({
    required this.x,
    required this.y,
    this.pressure = 0.5,
    this.tiltAzimuth = 0.0,
    this.tiltAltitude = 1.5707963, // pi/2
    this.timeOffsetMs = 0,
  });

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'pressure': pressure,
    'tiltAzimuth': tiltAzimuth,
    'tiltAltitude': tiltAltitude,
    'timeOffsetMs': timeOffsetMs,
  };

  factory InkPoint.fromJson(Map<String, dynamic> json) => InkPoint(
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    pressure: (json['pressure'] as num?)?.toDouble() ?? 0.5,
    tiltAzimuth: (json['tiltAzimuth'] as num?)?.toDouble() ?? 0.0,
    tiltAltitude: (json['tiltAltitude'] as num?)?.toDouble() ?? 1.5707963,
    timeOffsetMs: (json['timeOffsetMs'] as num?)?.toInt() ?? 0,
  );

  @override
  String toString() =>
      'InkPoint(x: $x, y: $y, p: ${pressure.toStringAsFixed(2)})';
}
