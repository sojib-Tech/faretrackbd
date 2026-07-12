import 'package:flutter_test/flutter_test.dart';
import 'package:faretrackbd/core/utils/fare_calculator.dart';

void main() {
  group('FareCalculator', () {
    test('calculateFare returns minimum fare for very short distances', () {
      expect(FareCalculator.calculateFare(0), 10.0);
      expect(FareCalculator.calculateFare(1), 10.0);
      expect(FareCalculator.calculateFare(3), 10.0);
    });

    test('calculateFare returns correct fare for distances over minimum', () {
      // 5 km * 2.53 = 12.65
      expect(FareCalculator.calculateFare(5), 12.65);
      // 10 km * 2.53 = 25.30
      expect(FareCalculator.calculateFare(10), 25.30);
    });

    test('calculateFare rounds to 2 decimal places', () {
      // 4 km * 2.53 = 10.12
      expect(FareCalculator.calculateFare(4), 10.12);
      // 8 km * 2.53 = 20.24
      expect(FareCalculator.calculateFare(8), 20.24);
    });

    test('calculateFare throws on negative distance', () {
      expect(
        () => FareCalculator.calculateFare(-1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('calculateFare works with zero distance', () {
      expect(FareCalculator.calculateFare(0), 10.0);
    });

    test('calculateAverageSpeed returns 0 for zero duration', () {
      expect(
        FareCalculator.calculateAverageSpeed(10, Duration.zero),
        0.0,
      );
    });

    test('calculateAverageSpeed returns correct speed', () {
      // 10 km in 30 minutes = 20 km/h
      final speed = FareCalculator.calculateAverageSpeed(
        10,
        const Duration(minutes: 30),
      );
      expect(speed, 20.0);
    });

    test('roundToTwo rounds correctly', () {
      expect(FareCalculator.roundToTwo(10.456), 10.46);
      expect(FareCalculator.roundToTwo(10.454), 10.45);
      expect(FareCalculator.roundToTwo(10.0), 10.0);
    });
  });
}
