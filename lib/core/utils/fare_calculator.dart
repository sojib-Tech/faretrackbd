import '../constants/app_strings.dart';

/// Calculates the Dhaka city bus fare based on BRTA rules.
///
/// [distanceInKm] is the travel distance in kilometers.
/// [isMinibus] sets whether the vehicle is a minibus (default is false/standard bus).
int calculateDhakaBusFare(double distanceInKm, {bool isMinibus = false}) {
  final double ratePerKm = isMinibus ? 2.43 : 2.53;
  final double minimumFare = isMinibus ? 8.0 : 10.0;

  double calculatedFare = distanceInKm * ratePerKm;

  if (calculatedFare < minimumFare) {
    return minimumFare.round();
  }

  return calculatedFare.round();
}

class FareCalculator {
  FareCalculator._();

  /// Calculate fare based on distance in kilometers using BRTA rules
  static double calculateFare(double distanceKm, {bool isMinibus = false}) {
    if (distanceKm < 0) {
      throw ArgumentError('Distance cannot be negative');
    }
    return calculateDhakaBusFare(distanceKm, isMinibus: isMinibus).toDouble();
  }

  /// Calculate fare and return as string with BDT symbol
  static String formatFare(double distanceKm, {bool isMinibus = false}) {
    return '${AppStrings.bdt}${calculateFare(distanceKm, isMinibus: isMinibus).toInt()}';
  }

  /// Calculate average speed in km/h
  static double calculateAverageSpeed(double distanceKm, Duration duration) {
    if (duration.inSeconds == 0) return 0;
    final hours = duration.inSeconds / 3600;
    if (hours == 0) return 0;
    return (distanceKm / hours * 100).roundToDouble() / 100;
  }

  /// Round to 2 decimal places
  static double roundToTwo(double value) {
    return (value * 100).roundToDouble() / 100;
  }
}
