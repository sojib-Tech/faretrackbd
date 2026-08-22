import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:faretrackbd/data/dhaka_bus_route_data.dart';
import 'package:faretrackbd/services/journey_planner_engine.dart';

void main() {
  late JourneyPlannerEngine engine;
  late List<DhakaBusRoute> allBuses;

  setUpAll(() {
    final file = File('assets/dhaka_bus_routes.json');
    final jsonStr = file.readAsStringSync();
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final list = data['buses'] as List<dynamic>;
    allBuses = list
        .map((e) => DhakaBusRoute.fromJson(e as Map<String, dynamic>))
        .toList();
    engine = JourneyPlannerEngine.createFromBuses(allBuses);
  });

  group('Direct matching correctness', () {
    test('Mugda → Jamuna Future Park should return exactly 7 buses', () {
      // Mugda/Mugdapara coordinate from StopCoordinates
      const originLat = 23.7200;
      const originLng = 90.4350;
      // Jamuna Future Park coordinate from StopCoordinates
      const destLat = 23.7920;
      const destLng = 90.4200;

      final candidates = engine.findDirectCandidates(
        originLat: originLat,
        originLng: originLng,
        destLat: destLat,
        destLng: destLng,
      );

      final busNames = candidates.map((c) => c.bus.nameEn).toList();

      // Print for debugging
      for (final c in candidates) {
        print(
          '${c.bus.nameBn} (${c.bus.nameEn}) | '
          'fare=৳${c.fare} | dist=${c.distanceKm.toStringAsFixed(2)}km | '
          'walk=${c.totalWalkMeters.toStringAsFixed(0)}m | '
          'origin=${c.originStop.stopName} → dest=${c.destStop.stopName}',
        );
      }

      // Expected exactly 7 buses
      expect(candidates.length, equals(7),
          reason: 'Expected 7 buses, got ${candidates.length}: $busNames');

      // Verify all expected buses are present
      final expectedBuses = [
        'Anabil Super',
        'Desh Bangla Bus',
        'Green Anabil',
        'J M Super Paribahan',
        'Raida',
        'Salsabil',
        'Turag',
      ];

      for (final expected in expectedBuses) {
        expect(busNames, contains(expected),
            reason: 'Missing expected bus: $expected');
      }

      // Verify no extras
      for (final name in busNames) {
        expect(expectedBuses, contains(name),
            reason: 'Unexpected bus found: $name');
      }
    });

    test('all buses load from JSON', () {
      expect(allBuses.length, greaterThanOrEqualTo(180));
    });

    test('engine finds candidates for a common route', () {
      // Motijheel → Uttara (common route)
      final candidates = engine.findDirectCandidates(
        originLat: 23.7330,
        originLng: 90.4180,
        destLat: 23.8750,
        destLng: 90.3790,
      );
      expect(candidates.length, greaterThan(0));
    });

    test('no candidates for route beyond walk radius', () {
      // Middle of river - no stops within 800m
      final candidates = engine.findDirectCandidates(
        originLat: 23.7800,
        originLng: 90.4500,
        destLat: 23.8750,
        destLng: 90.3790,
      );
      expect(candidates.length, equals(0));
    });
  });
}
