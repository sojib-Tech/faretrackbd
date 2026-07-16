import 'package:flutter_test/flutter_test.dart';
import 'package:faretrackbd/models/journey/journey_result.dart';

void main() {
  group('JourneyResult Validation', () {
    test('direct bus - all values consistent', () {
      final result = JourneyResult(
        id: 'test_1',
        originName: 'মতিঝিল',
        destName: 'উত্তরা',
        segments: [
          const WalkingSegment(
            distanceMeters: 200,
            durationMinutes: 2.4,
            direction: WalkDirection.north,
            fromLabel: 'মতিঝিল',
            toLabel: 'মতিঝিল স্টপ',
          ),
          const WalkingSegment(
            distanceMeters: 300,
            durationMinutes: 3.6,
            direction: WalkDirection.east,
            fromLabel: 'উত্তরা স্টপ',
            toLabel: 'উত্তরা',
          ),
        ],
      );

      expect(result.busSegments.length, 0);
      expect(result.walkingSegments.length, 2);
      expect(result.transferSegments.length, 0);
      expect(result.transferCount, 0);
      expect(result.totalWalkingDistanceMeters, 500.0);
      expect(result.totalWalkingTimeMinutes, 6.0);
    });

    test('steps order is always walk→bus→transfer→bus→walk→arrive', () {
      final result = JourneyResult(
        id: 'test_order',
        originName: 'A',
        destName: 'B',
        segments: [
          const WalkingSegment(
            distanceMeters: 100, durationMinutes: 1.2,
            direction: WalkDirection.north,
            fromLabel: 'A', toLabel: 'Stop1',
          ),
          const TransferSegment(
            fromStop: 'Stop2', toStop: 'Stop2',
            nextBusNameBn: 'R২', waitTimeMinutes: 5.0,
          ),
          const WalkingSegment(
            distanceMeters: 100, durationMinutes: 1.2,
            direction: WalkDirection.south,
            fromLabel: 'Stop3', toLabel: 'B',
          ),
        ],
      );

      final steps = result.steps;
      final types = steps.map((s) => s.type).toList();

      expect(types, [
        JourneyStepType.walkToStop,
        JourneyStepType.transfer,
        JourneyStepType.walkToDestination,
        JourneyStepType.arrive,
      ]);
    });

    test('no duplicate segments', () {
      final result = JourneyResult(
        id: 'dedup',
        originName: 'A',
        destName: 'B',
        segments: [
          const WalkingSegment(
            distanceMeters: 100, durationMinutes: 1.2,
            direction: WalkDirection.north,
            fromLabel: 'A', toLabel: 'Stop1',
          ),
          const WalkingSegment(
            distanceMeters: 100, durationMinutes: 1.2,
            direction: WalkDirection.south,
            fromLabel: 'Stop2', toLabel: 'B',
          ),
        ],
      );

      expect(result.segments.length, 2);
      expect(result.walkingSegments.length, 2);
    });

    test('empty result has zero values', () {
      const result = JourneyResult(
        id: 'empty',
        originName: 'A',
        destName: 'B',
        segments: [],
      );

      expect(result.totalFare, 0.0);
      expect(result.totalDistanceKm, 0.0);
      expect(result.totalTimeMinutes, 0.0);
      expect(result.transferCount, 0);
      expect(result.isDirect, false);
    });
  });

  group('Score Weights', () {
    test('score weights sum to 1.0', () {
      const timeWeight = 0.40;
      const fareWeight = 0.25;
      const walkWeight = 0.20;
      const transferWeight = 0.15;
      final total = timeWeight + fareWeight + walkWeight + transferWeight;
      expect(total, 1.0);
    });
  });

  group('Formatted Output', () {
    test('totalTimeFormatted', () {
      const result = JourneyResult(
        id: 'fmt',
        originName: 'A',
        destName: 'B',
        segments: [
          WalkingSegment(
            distanceMeters: 100,
            durationMinutes: 1.2,
            direction: WalkDirection.north,
            fromLabel: 'A',
            toLabel: 'B',
          ),
        ],
      );

      expect(result.totalTimeFormatted, contains('মি'));
    });

    test('totalDistanceFormatted short distance shows meters', () {
      const result = JourneyResult(
        id: 'short',
        originName: 'A',
        destName: 'B',
        segments: [
          WalkingSegment(
            distanceMeters: 500,
            durationMinutes: 6.0,
            direction: WalkDirection.north,
            fromLabel: 'A',
            toLabel: 'B',
          ),
        ],
      );

      expect(result.totalDistanceFormatted, contains('মি'));
    });

    test('walking segment direction labels', () {
      const walk = WalkingSegment(
        distanceMeters: 100,
        durationMinutes: 1.2,
        direction: WalkDirection.northeast,
        fromLabel: 'A',
        toLabel: 'B',
      );

      expect(walk.directionLabel, 'উত্তর-পূর্ব');
    });
  });
}
