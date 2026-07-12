import 'dart:convert';
import 'package:flutter/services.dart';

class BusInfo {
  final int id;
  final String name;
  final String nameBn;
  final String type;
  final bool checkSystem;
  final String? time;
  final List<String> stops;

  const BusInfo({
    required this.id,
    required this.name,
    required this.nameBn,
    required this.stops,
    this.type = '',
    this.checkSystem = false,
    this.time,
  });

  factory BusInfo.fromJson(Map<String, dynamic> json) {
    return BusInfo(
      id: json['id'] as int,
      name: json['name'] as String,
      nameBn: json['name_bn'] as String,
      type: json['type'] as String? ?? '',
      checkSystem: json['check_system'] as bool? ?? false,
      time: json['time'] as String?,
      stops: (json['stops'] as List?)?.cast<String>() ?? [],
    );
  }

  List<String> get searchKeywords {
    final keywords = <String>{name, nameBn};
    for (final s in stops) {
      if (s.length > 2) keywords.add(s);
    }
    return keywords.toList();
  }
}

class BusDatabase {
  static List<BusInfo>? _cachedAll;

  static Future<void> initialize() async {
    if (_cachedAll != null) return;
    final jsonStr = await rootBundle.loadString('assets/bus_data.json');
    final list = jsonDecode(jsonStr) as List;
    _cachedAll = list.map((e) => BusInfo.fromJson(e as Map<String, dynamic>)).toList();
  }

  static List<BusInfo> get allBuses => _cachedAll ?? [];

  static List<BusInfo> searchByName(String query) {
    if (_cachedAll == null || query.trim().isEmpty) return [];
    final q = query.toLowerCase().trim();

    if (q.length == 1) {
      final firstLetter = q;
      return _cachedAll!.where((bus) {
        if (bus.name.isNotEmpty && bus.name[0].toLowerCase() == firstLetter) return true;
        if (bus.nameBn.isNotEmpty && bus.nameBn[0].toLowerCase() == firstLetter) return true;
        return false;
      }).toList();
    }

    return _cachedAll!.where((bus) {
      if (bus.name.toLowerCase().contains(q)) return true;
      if (bus.nameBn.toLowerCase().contains(q)) return true;
      for (final stop in bus.stops) {
        if (stop.toLowerCase().contains(q)) return true;
      }
      return false;
    }).toList();
  }
}
