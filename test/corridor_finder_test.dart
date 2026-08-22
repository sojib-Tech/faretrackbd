import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:faretrackbd/data/corridor_finder.dart';

void main() {
  late List<CorridorBusRoute> allBuses;

  setUpAll(() {
    final file = File('assets/dhaka_bus_routes.json');
    final jsonStr = file.readAsStringSync();
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final list = data['buses'] as List<dynamic>;
    allBuses = list.map((e) {
      final m = e as Map<String, dynamic>;
      return CorridorBusRoute(
        nameEn: m['name_en'] as String? ?? '',
        nameBn: m['name_bn'] as String? ?? '',
        stops: (m['route'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
        type: m['type'] as String?,
        time: m['time'] as String?,
      );
    }).toList();
  });

  group('Text-based corridor matching', () {
    test('Mugda → Jamuna Future Park returns exactly 7 buses', () {
      final matches = findCorridorBuses(allBuses, 'Mugda', 'Jamuna Future Park');

      final busNames = matches.map((b) => b.nameEn).toList();
      print('Matched buses: $busNames (${matches.length})');

      expect(matches.length, equals(7),
          reason: 'Expected 7 buses, got ${matches.length}: $busNames');

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

      for (final name in busNames) {
        expect(expectedBuses, contains(name),
            reason: 'Unexpected bus found: $name');
      }
    });

    test('no match when origin and destination are same stop', () {
      final matches = findCorridorBuses(allBuses, 'Farmgate', 'Farmgate');
      expect(matches.length, equals(0));
    });

    test('returns empty for unknown place', () {
      final matches = findCorridorBuses(allBuses, 'Atlantis', 'Farmgate');
      expect(matches.length, equals(0));
    });

    test('Bidirectional matching works', () {
      final forward = findCorridorBuses(allBuses, 'Farmgate', 'Uttara');
      final backward = findCorridorBuses(allBuses, 'Uttara', 'Farmgate');
      expect(forward.length, greaterThan(0));
      expect(forward.length, equals(backward.length));
    });

    test('all 182 buses load from JSON', () {
      expect(allBuses.length, greaterThanOrEqualTo(180));
    });
  });
}
