import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/journey/stop_coordinate.dart';
import '../models/zone_model.dart';
import 'stop_coordinates.dart';

class DhakaZoneData {
  DhakaZoneData._();

  static Future<List<DhakaZone>> getZones() async {
    final jsonStr = await rootBundle.loadString('assets/dhaka_zones.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final features = data['features'] as List;
    return features
        .map((f) => DhakaZone.fromJson(f as Map<String, dynamic>))
        .toList();
  }

  static Future<List<StopCoordinate>> getStopsInZone(DhakaZone zone) async {
    final allStops = StopCoordinates.all;
    final ring = zone.coordinates[0];
    return allStops.where((stop) => _isPointInPolygon(stop.lat, stop.lng, ring)).toList();
  }

  static bool _isPointInPolygon(double lat, double lng, List<List<double>> polygon) {
    bool inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i][0], yi = polygon[i][1];
      final xj = polygon[j][0], yj = polygon[j][1];
      if (((yi > lat) != (yj > lat)) && (lng < (xj - xi) * (lat - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
    }
    return inside;
  }
}
