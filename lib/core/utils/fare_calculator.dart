import '../constants/app_constants.dart';
import '../constants/app_strings.dart';

class FareCalculator {
  FareCalculator._();

  /// Calculate fare based on distance in kilometers
  ///
  /// Formula:
  /// if distance * ratePerKm <= minimumFare, return minimumFare
  /// else return distance * ratePerKm
  ///
  /// Result is rounded to 2 decimal places
  static double calculateFare(double distanceKm) {
    if (distanceKm < 0) {
      throw ArgumentError('Distance cannot be negative');
    }

    final calculated = distanceKm * AppConstants.fareRatePerKm;
    final fare = calculated <= AppConstants.minimumFare
        ? AppConstants.minimumFare
        : calculated;

    return (fare * 100).roundToDouble() / 100;
  }

  /// Calculate fare and return as string with BDT symbol
  static String formatFare(double distanceKm) {
    return '${AppStrings.bdt}${calculateFare(distanceKm).toStringAsFixed(2)}';
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
