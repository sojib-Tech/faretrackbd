import 'package:flutter_test/flutter_test.dart';
import 'package:faretrackbd/core/utils/fare_calculator.dart';

void main() {
  test('FareCalculator returns correct values', () {
    expect(FareCalculator.calculateFare(0), 10.0);
    expect(FareCalculator.calculateFare(5), 12.65);
    expect(FareCalculator.calculateFare(10), 25.30);
  });

  test('FareCalculator throws on negative distance', () {
    expect(
      () => FareCalculator.calculateFare(-1),
      throwsA(isA<ArgumentError>()),
    );
  });
}
