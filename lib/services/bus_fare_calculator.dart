import '../models/bus_route.dart';
import '../data/bus_route_data.dart';
import '../core/utils/fare_calculator.dart';

class FareCalculationResult {
  final BusRoute route;
  final BusStop fromStop;
  final BusStop toStop;
  final double fare;
  final double distanceKm;

  const FareCalculationResult({
    required this.route,
    required this.fromStop,
    required this.toStop,
    required this.fare,
    required this.distanceKm,
  });

  String get formattedFare => '৳${fare.toInt()}';
  String get formattedDistance => '${distanceKm.toStringAsFixed(1)} কিমি';
}

class BusFareCalculator {
  static double calculateFareByDistance(double distanceKm, {bool isMinibus = false}) {
    return calculateDhakaBusFare(distanceKm, isMinibus: isMinibus).toDouble();
  }

  static FareCalculationResult? findFare({
    required String routeId,
    required String fromStopName,
    required String toStopName,
  }) {
    final route = BusRouteData.findById(routeId);
    if (route == null) return null;

    int? fromIdx;
    int? toIdx;
    for (int i = 0; i < route.stops.length; i++) {
      if (route.stops[i].name == fromStopName) fromIdx = i;
      if (route.stops[i].name == toStopName) toIdx = i;
    }
    if (fromIdx == null || toIdx == null) return null;

    final fare = route.getFare(fromIdx, toIdx);
    final distance = route.getDistanceBetween(fromIdx, toIdx);
    if (fare == null || distance == null) return null;

    return FareCalculationResult(
      route: route,
      fromStop: route.stops[fromIdx],
      toStop: route.stops[toIdx],
      fare: fare,
      distanceKm: distance,
    );
  }

  static List<BusRoute> findRoutesContaining({
    required String stopName,
  }) {
    final q = stopName.toLowerCase();
    return BusRouteData.allRoutes.where((r) {
      return r.stops.any((s) => s.name.toLowerCase().contains(q));
    }).toList();
  }

  static List<FareCalculationResult> findFaresBetweenStops({
    required String fromStop,
    required String toStop,
  }) {
    final results = <FareCalculationResult>[];
    for (final route in BusRouteData.allRoutes) {
      int? fromIdx;
      int? toIdx;
      for (int i = 0; i < route.stops.length; i++) {
        if (route.stops[i].name.contains(fromStop)) fromIdx = i;
        if (route.stops[i].name.contains(toStop)) toIdx = i;
      }
      if (fromIdx != null && toIdx != null) {
        final distance = route.getDistanceBetween(fromIdx, toIdx);
        if (distance != null && distance > 0) {
          final fare = route.getFare(fromIdx, toIdx) ?? calculateDhakaBusFare(distance).toDouble();
          results.add(FareCalculationResult(
            route: route,
            fromStop: route.stops[fromIdx],
            toStop: route.stops[toIdx],
            fare: fare,
            distanceKm: distance,
          ));
        }
      }
    }
    return results;
  }
}
