import 'dart:math';
import '../data/dhaka_bus_route_data.dart';
import '../models/journey/stop_coordinate.dart';
import '../core/utils/fare_calculator.dart';

class ResolvedBusStop {
  final int routeIndex;
  final String stopName;
  final StopCoordinate? coordinate;

  const ResolvedBusStop({
    required this.routeIndex,
    required this.stopName,
    this.coordinate,
  });
}

class ResolvedBusRoute {
  final String nameEn;
  final String nameBn;
  final String? type;
  final String? time;
  final List<String> rawRoute;
  final List<ResolvedBusStop> resolvedStops;

  const ResolvedBusRoute({
    required this.nameEn,
    required this.nameBn,
    required this.rawRoute,
    required this.resolvedStops,
    this.type,
    this.time,
  });

  bool get isAc =>
      (type?.toLowerCase().contains('ac') ?? false) ||
      nameBn.toLowerCase().contains('ac') ||
      nameEn.toLowerCase().contains('ac');
}

class DirectCandidate {
  final ResolvedBusRoute bus;
  final ResolvedBusStop originStop;
  final ResolvedBusStop destStop;
  final double distanceKm;
  final double fare;
  final int stopsBetween;
  final double originWalkMeters;
  final double destWalkMeters;

  const DirectCandidate({
    required this.bus,
    required this.originStop,
    required this.destStop,
    required this.distanceKm,
    required this.fare,
    required this.stopsBetween,
    required this.originWalkMeters,
    required this.destWalkMeters,
  });

  double get totalWalkMeters => originWalkMeters + destWalkMeters;
  double get totalWalkMinutes => totalWalkMeters / 1000.0 / 5.0 * 60.0;
  double get busTimeMinutes => distanceKm / 20.0 * 60.0;
  double get totalTimeMinutes => totalWalkMinutes + busTimeMinutes;
}

class JourneyPlannerEngine {
  final double walkRadiusMeters;
  final List<ResolvedBusRoute> _resolvedRoutes;

  JourneyPlannerEngine._(this._resolvedRoutes, {this.walkRadiusMeters = 800.0});

  static Future<JourneyPlannerEngine> create({
    double walkRadiusMeters = 800.0,
  }) async {
    final buses = await DhakaBusRouteData.load();
    return createFromBuses(buses, walkRadiusMeters: walkRadiusMeters);
  }

  static JourneyPlannerEngine createFromBuses(
    List<DhakaBusRoute> buses, {
    double walkRadiusMeters = 800.0,
  }) {
    final resolved = <ResolvedBusRoute>[];
    for (final bus in buses) {
      final resolvedStops = <ResolvedBusStop>[];
      for (var i = 0; i < bus.route.length; i++) {
        final stopName = bus.route[i];
        final coord = DhakaBusRouteData.findStop(stopName);
        resolvedStops.add(ResolvedBusStop(
          routeIndex: i,
          stopName: stopName,
          coordinate: coord,
        ));
      }
      resolved.add(ResolvedBusRoute(
        nameEn: bus.nameEn,
        nameBn: bus.nameBn,
        rawRoute: bus.route,
        resolvedStops: resolvedStops,
        type: bus.type,
        time: bus.time,
      ));
    }
    return JourneyPlannerEngine._(resolved, walkRadiusMeters: walkRadiusMeters);
  }

  static double haversine(double lat1, double lng1, double lat2, double lng2) {
    const earthRadius = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRad(double deg) => deg * pi / 180.0;

  List<DirectCandidate> findDirectCandidates({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) {
    final results = <DirectCandidate>[];

    for (final bus in _resolvedRoutes) {
      if (bus.resolvedStops.length < 2) continue;

      final originStop = _findNearestStopWithinRadius(
        bus, originLat, originLng,
      );
      if (originStop == null) continue;

      final destStop = _findNearestStopWithinRadiusExcluding(
        bus, destLat, destLng, originStop.routeIndex,
      );
      if (destStop == null) continue;

      final distanceKm = _routeDistanceBetween(bus, originStop.routeIndex, destStop.routeIndex);
      if (distanceKm <= 0) continue;

      final fare = calculateDhakaBusFare(distanceKm).toDouble();
      final stopsBetween = (destStop.routeIndex - originStop.routeIndex).abs() - 1;

      results.add(DirectCandidate(
        bus: bus,
        originStop: originStop,
        destStop: destStop,
        distanceKm: distanceKm,
        fare: fare,
        stopsBetween: stopsBetween,
        originWalkMeters: originStop.coordinate != null
            ? haversine(originLat, originLng, originStop.coordinate!.lat, originStop.coordinate!.lng)
            : 0,
        destWalkMeters: destStop.coordinate != null
            ? haversine(destLat, destLng, destStop.coordinate!.lat, destStop.coordinate!.lng)
            : 0,
      ));
    }

    results.sort((a, b) => a.fare.compareTo(b.fare));
    return results;
  }

  ResolvedBusStop? _findNearestStopWithinRadius(
    ResolvedBusRoute bus,
    double lat,
    double lng,
  ) {
    ResolvedBusStop? best;
    double bestDist = double.infinity;

    for (final stop in bus.resolvedStops) {
      if (stop.coordinate == null) continue;
      final dist = haversine(lat, lng, stop.coordinate!.lat, stop.coordinate!.lng);
      if (dist <= walkRadiusMeters && dist < bestDist) {
        bestDist = dist;
        best = stop;
      }
    }

    return best;
  }

  ResolvedBusStop? _findNearestStopWithinRadiusExcluding(
    ResolvedBusRoute bus,
    double lat,
    double lng,
    int excludeIndex,
  ) {
    ResolvedBusStop? best;
    double bestDist = double.infinity;

    for (final stop in bus.resolvedStops) {
      if (stop.routeIndex == excludeIndex) continue;
      if (stop.coordinate == null) continue;
      final dist = haversine(lat, lng, stop.coordinate!.lat, stop.coordinate!.lng);
      if (dist <= walkRadiusMeters && dist < bestDist) {
        bestDist = dist;
        best = stop;
      }
    }

    return best;
  }

  double _routeDistanceBetween(ResolvedBusRoute bus, int fromIdx, int toIdx) {
    final low = min(fromIdx, toIdx);
    final high = max(fromIdx, toIdx);

    double totalMeters = 0;
    for (var i = low; i < high; i++) {
      final a = bus.resolvedStops[i].coordinate;
      final b = bus.resolvedStops[i + 1].coordinate;
      if (a != null && b != null) {
        totalMeters += haversine(a.lat, a.lng, b.lat, b.lng);
      }
    }

    if (totalMeters > 0) return totalMeters / 1000.0;

    final fromStop = bus.resolvedStops[low].coordinate;
    final toStop = bus.resolvedStops[high].coordinate;
    if (fromStop != null && toStop != null) {
      return haversine(fromStop.lat, fromStop.lng, toStop.lat, toStop.lng) / 1000.0;
    }

    return (high - low) * 0.5;
  }

  List<String> getMatchingBusNames({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) {
    return findDirectCandidates(
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
    ).map((c) => c.bus.nameEn).toList();
  }
}
