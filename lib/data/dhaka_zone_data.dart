import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/journey/stop_coordinate.dart';
import '../models/zone_model.dart';
import 'stop_coordinates.dart';

class DhakaZoneData {
  static List<DhakaZone>? _zones;

  static Future<List<DhakaZone>> getZones() async {
    if (_zones != null) return _zones!;

    final jsonStr = await rootBundle.loadString('assets/dhaka_zones.json');
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    final features = json['features'] as List;

    _zones = features
        .map((f) => DhakaZone.fromJson(f as Map<String, dynamic>))
        .toList();

    return _zones!;
  }

  static Future<DhakaZone?> getZoneById(int id) async {
    final zones = await getZones();
    try {
      return zones.firstWhere((z) => z.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<DhakaZone?> findZoneContaining(double lat, double lng) async {
    final zones = await getZones();
    for (final zone in zones) {
      if (_pointInPolygon(lat, lng, zone.coordinates[0])) {
        return zone;
      }
    }
    return null;
  }

  static Future<List<StopCoordinate>> getStopsInZone(DhakaZone zone) async {
    final polygon = zone.coordinates[0];
    return StopCoordinates.all.where((stop) {
      return _pointInPolygon(stop.lat, stop.lng, polygon);
    }).toList();
  }

  static bool _pointInPolygon(double lat, double lng, List<List<double>> polygon) {
    int intersections = 0;
    final n = polygon.length;

    for (int i = 0; i < n; i++) {
      final p1 = polygon[i];
      final p2 = polygon[(i + 1) % n];

      final lat1 = p1[1];
      final lng1 = p1[0];
      final lat2 = p2[1];
      final lng2 = p2[0];

      if (((lat1 > lat) != (lat2 > lat)) &&
          (lng < (lng2 - lng1) * (lat - lat1) / (lat2 - lat1) + lng1)) {
        intersections++;
      }
    }

    return intersections % 2 == 1;
  }
}
