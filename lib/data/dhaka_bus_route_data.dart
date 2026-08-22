import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/journey/stop_coordinate.dart';
import 'stop_coordinates.dart';

class DhakaBusRoute {
  final String nameEn;
  final String nameBn;
  final List<String> route;
  final String? type;
  final String? time;

  const DhakaBusRoute({
    required this.nameEn,
    required this.nameBn,
    required this.route,
    this.type,
    this.time,
  });

  factory DhakaBusRoute.fromJson(Map<String, dynamic> json) {
    return DhakaBusRoute(
      nameEn: json['name_en'] as String? ?? '',
      nameBn: json['name_bn'] as String? ?? '',
      route: (json['route'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      type: json['type'] as String?,
      time: json['time'] as String?,
    );
  }
}

class DhakaBusRouteData {
  DhakaBusRouteData._();

  static List<DhakaBusRoute>? _buses;
  static Map<String, StopCoordinate>? _normalizedStops;

  static Future<List<DhakaBusRoute>> load() async {
    if (_buses != null) return _buses!;
    final jsonStr = await rootBundle.loadString('assets/dhaka_bus_routes.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final list = data['buses'] as List<dynamic>;
    _buses = list
        .map((e) => DhakaBusRoute.fromJson(e as Map<String, dynamic>))
        .toList();
    return _buses!;
  }

  static List<DhakaBusRoute> get all => _buses ?? [];

  static Map<String, StopCoordinate> get normalizedStops {
    if (_normalizedStops != null) return _normalizedStops!;
    _normalizedStops = <String, StopCoordinate>{};
    for (final stop in StopCoordinates.all) {
      _normalizedStops![_normalize(stop.name)] = stop;
    }
    return _normalizedStops!;
  }

  static String _normalize(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '');
  }

  static StopCoordinate? findStop(String englishName) {
    final normalized = _normalize(englishName);

    final exact = StopCoordinates.find(englishName);
    if (exact != null) return exact;

    final normalizedMap = normalizedStops;
    if (normalizedMap.containsKey(normalized)) {
      return normalizedMap[normalized];
    }

    for (final entry in normalizedMap.entries) {
      if (entry.key.contains(normalized) || normalized.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  static List<StopCoordinate> resolveRoute(String stopName) {
    final stop = findStop(stopName);
    return stop != null ? [stop] : [];
  }
}
