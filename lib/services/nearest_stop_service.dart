import 'dart:math';
import '../models/journey/stop_coordinate.dart';
import '../data/stop_coordinates.dart';

class NearbyStop {
  final StopCoordinate coordinate;
  final double distanceMeters;
  final double walkingTimeMinutes;
  final String direction;

  const NearbyStop({
    required this.coordinate,
    required this.distanceMeters,
    required this.walkingTimeMinutes,
    required this.direction,
  });
}

class NearestStopService {
  static const double _walkingSpeedKmh = 5.0;

  static double haversine(double lat1, double lng1, double lat2, double lng2) {
    const earthRadius = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRad(double deg) => deg * pi / 180.0;

  static String _getDirection(double lat1, double lng1, double lat2, double lng2) {
    final dLat = lat2 - lat1;
    final dLng = lng2 - lng1;
    final angle = atan2(dLng, dLat) * 180 / pi;

    if (angle >= -22.5 && angle < 22.5) return 'উত্তর';
    if (angle >= 22.5 && angle < 67.5) return 'উত্তর-পূর্ব';
    if (angle >= 67.5 && angle < 112.5) return 'পূর্ব';
    if (angle >= 112.5 && angle < 157.5) return 'দক্ষিণ-পূর্ব';
    if (angle >= 157.5 || angle < -157.5) return 'দক্ষিণ';
    if (angle >= -157.5 && angle < -112.5) return 'দক্ষিণ-পশ্চিম';
    if (angle >= -112.5 && angle < -67.5) return 'পশ্চিম';
    return 'উত্তর-পশ্চিম';
  }

  static List<NearbyStop> findNearby({
    required double latitude,
    required double longitude,
    double radiusMeters = 1000.0,
  }) {
    final results = <NearbyStop>[];

    for (final coord in StopCoordinates.all) {
      final dist = haversine(latitude, longitude, coord.lat, coord.lng);
      if (dist <= radiusMeters) {
        final walkMin = (dist / 1000.0 / _walkingSpeedKmh) * 60.0;
        final dir = _getDirection(latitude, longitude, coord.lat, coord.lng);
        results.add(NearbyStop(
          coordinate: coord,
          distanceMeters: dist,
          walkingTimeMinutes: walkMin,
          direction: dir,
        ));
      }
    }

    results.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return results;
  }

  static Map<String, List<NearbyStop>> findByRadius({
    required double latitude,
    required double longitude,
  }) {
    return {
      '৩০০মি': findNearby(latitude: latitude, longitude: longitude, radiusMeters: 300),
      '৫০০মি': findNearby(latitude: latitude, longitude: longitude, radiusMeters: 500),
      '৮০০মি': findNearby(latitude: latitude, longitude: longitude, radiusMeters: 800),
      '১ কিমি': findNearby(latitude: latitude, longitude: longitude, radiusMeters: 1000),
    };
  }
}
