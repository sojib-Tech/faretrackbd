import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoadRouter {
  static const _baseUrl = 'https://router.project-osrm.org/route/v1/driving';

  static Future<List<LatLng>> getRoadRoute(List<LatLng> points) async {
    if (points.length < 2) return points;

    try {
      final coords = points
          .map((p) => '${p.longitude.toStringAsFixed(6)},${p.latitude.toStringAsFixed(6)}')
          .join(';');

      final url = '$_baseUrl/$coords?overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          final geometry = data['routes'][0]['geometry'];
          return _decodeGeoJson(geometry);
        }
      }
    } catch (e) {
      debugPrint('RoadRouter error: $e');
    }

    return points;
  }

  static List<LatLng> _decodeGeoJson(dynamic geometry) {
    final coords = geometry['coordinates'] as List;
    return coords.map<LatLng>((c) {
      return LatLng(c[1] as double, c[0] as double);
    }).toList();
  }
}
