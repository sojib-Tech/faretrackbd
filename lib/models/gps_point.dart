class GpsPoint {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double speed;
  final double heading;
  final DateTime timestamp;

  GpsPoint({
    required this.latitude,
    required this.longitude,
    this.accuracy = 0,
    this.speed = 0,
    this.heading = 0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() =>
      'GpsPoint(lat: $latitude, lng: $longitude, acc: $accuracy, speed: $speed)';
}
