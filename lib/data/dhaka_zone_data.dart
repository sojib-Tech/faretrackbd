import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/journey/stop_coordinate.dart';

class DhakaZoneData {

  static Future<List<DhakaZone>> getZones() async {
      final jsonStr = await rootBundle.loadString('assets/dhaka_zones.json');
  }

    try {
    }
  }

  static Future<List<StopCoordinate>> getStopsInZone(DhakaZone zone) async {
  }
}
