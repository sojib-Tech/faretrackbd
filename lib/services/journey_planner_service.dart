import '../core/utils/fare_calculator.dart';
import '../data/bus_route_data.dart';
import '../data/stop_coordinates.dart';
import '../models/bus_route.dart';
import '../models/journey/journey_plan.dart';
import 'eta_service.dart';
import 'nearest_stop_service.dart';
import 'scoring_service.dart';

class JourneyPlannerService {
  static final Map<String, List<_RouteStopInfo>> _stopToRoutes = {};

  static void _buildIndex() {
    if (_stopToRoutes.isNotEmpty) return;
    _stopToRoutes.clear();

    for (final route in BusRouteData.allRoutes) {
      for (var i = 0; i < route.stops.length; i++) {
        final name = route.stops[i].name;
        _stopToRoutes.putIfAbsent(name, () => []).add(
          _RouteStopInfo(route: route, index: i),
        );
        final coord = StopCoordinates.find(name);
        if (coord != null && coord.nameBn != name) {
          _stopToRoutes.putIfAbsent(coord.nameBn, () => []).add(
            _RouteStopInfo(route: route, index: i),
          );
        }
      }
    }
  }

  static List<JourneyPlan> planJourney({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required String originName,
    required String destName,
  }) {
    _buildIndex();

    final nearbyOrigin = NearestStopService.findNearby(
      latitude: originLat,
      longitude: originLng,
      radiusMeters: 1500,
    );

    final nearbyDest = NearestStopService.findNearby(
      latitude: destLat,
      longitude: destLng,
      radiusMeters: 1500,
    );

    if (nearbyOrigin.isEmpty || nearbyDest.isEmpty) return [];

    final plans = <JourneyPlan>[];
    var planId = 0;

    for (final origStop in nearbyOrigin.take(5)) {
      for (final destStop in nearbyDest.take(5)) {
        final origRoutes = _stopToRoutes[origStop.coordinate.nameBn] ??
            _stopToRoutes[origStop.coordinate.name] ?? [];
        final destRoutes = _stopToRoutes[destStop.coordinate.nameBn] ??
            _stopToRoutes[destStop.coordinate.name] ?? [];

        for (final origInfo in origRoutes) {
          for (final destInfo in destRoutes) {
            if (origInfo.route.id == destInfo.route.id &&
                origInfo.index < destInfo.index) {
              final leg = _createLeg(
                origInfo.route,
                origInfo.index,
                destInfo.index,
              );
              if (leg != null) {
                final walkDist = origStop.distanceMeters + destStop.distanceMeters;
                final totalETA = EtaService.calculateETA(
                  walkDistanceMeters: walkDist,
                  busDistanceKm: leg.distanceKm,
                  transferCount: 0,
                );

                plans.add(JourneyPlan(
                  id: 'plan_${++planId}',
                  legs: [leg],
                  initialWalk: WalkSegment(
                    distanceMeters: origStop.distanceMeters,
                    durationMinutes: origStop.walkingTimeMinutes,
                    direction: _getWalkDirection(origStop.direction),
                    fromLabel: originName,
                    toLabel: origStop.coordinate.nameBn,
                  ),
                  finalWalk: WalkSegment(
                    distanceMeters: destStop.distanceMeters,
                    durationMinutes: destStop.walkingTimeMinutes,
                    direction: _getWalkDirection(destStop.direction),
                    fromLabel: destStop.coordinate.nameBn,
                    toLabel: destName,
                  ),
                  totalFare: leg.fare,
                  totalWalkDistanceMeters: walkDist,
                  totalWalkMinutes: origStop.walkingTimeMinutes + destStop.walkingTimeMinutes,
                  totalBusMinutes: leg.estimatedMinutes,
                  totalTransferWaitMinutes: 0,
                  totalETA: totalETA,
                  smartScore: 0,
                  preference: RoutePreference.recommended,
                  transferCount: 0,
                ));
              }
            }
          }
        }
      }
    }

    if (plans.isEmpty) {
      plans.addAll(_findTransferPlans(
        nearbyOrigin: nearbyOrigin.take(3).toList(),
        nearbyDest: nearbyDest.take(3).toList(),
        originName: originName,
        destName: destName,
        planIdStart: planId,
      ));
    }

    return ScoringService.rank(plans);
  }

  static List<JourneyPlan> _findTransferPlans({
    required List<NearbyStop> nearbyOrigin,
    required List<NearbyStop> nearbyDest,
    required String originName,
    required String destName,
    required int planIdStart,
  }) {
    final plans = <JourneyPlan>[];
    var planId = planIdStart;

    for (final origStop in nearbyOrigin) {
      for (final destStop in nearbyDest) {
        final origRoutes = _stopToRoutes[origStop.coordinate.nameBn] ??
            _stopToRoutes[origStop.coordinate.name] ?? [];
        final destRoutes = _stopToRoutes[destStop.coordinate.nameBn] ??
            _stopToRoutes[destStop.coordinate.name] ?? [];

        for (final origInfo in origRoutes) {
          for (final destInfo in destRoutes) {
            if (origInfo.route.id == destInfo.route.id) continue;

            final commonStop = _findCommonStop(
              origInfo.route,
              destInfo.route,
              origInfo.index,
              destInfo.index,
            );
            if (commonStop == null) continue;

            final leg1 = _createLeg(origInfo.route, origInfo.index, commonStop.index1);
            final leg2 = _createLeg(destInfo.route, commonStop.index2, destInfo.index);

            if (leg1 == null || leg2 == null) continue;

            final walkDist = origStop.distanceMeters + destStop.distanceMeters;
            final totalFare = leg1.fare + leg2.fare;
            final totalETA = EtaService.calculateETA(
              walkDistanceMeters: walkDist,
              busDistanceKm: leg1.distanceKm + leg2.distanceKm,
              transferCount: 1,
            );

            final totalWalkMin = origStop.walkingTimeMinutes + destStop.walkingTimeMinutes;
            final totalBusMin = leg1.estimatedMinutes + leg2.estimatedMinutes;
            final totalTransferWait = EtaService.estimateTransferWait();

            plans.add(JourneyPlan(
              id: 'plan_${++planId}',
              legs: [leg1, leg2],
              initialWalk: WalkSegment(
                distanceMeters: origStop.distanceMeters,
                durationMinutes: origStop.walkingTimeMinutes,
                direction: _getWalkDirection(origStop.direction),
                fromLabel: originName,
                toLabel: origStop.coordinate.nameBn,
              ),
              finalWalk: WalkSegment(
                distanceMeters: destStop.distanceMeters,
                durationMinutes: destStop.walkingTimeMinutes,
                direction: _getWalkDirection(destStop.direction),
                fromLabel: destStop.coordinate.nameBn,
                toLabel: destName,
              ),
              totalFare: totalFare,
              totalWalkDistanceMeters: walkDist,
              totalWalkMinutes: totalWalkMin,
              totalBusMinutes: totalBusMin,
              totalTransferWaitMinutes: totalTransferWait,
              totalETA: totalETA,
              smartScore: 0,
              preference: RoutePreference.recommended,
              transferCount: 1,
            ));
          }
        }
      }
    }

    return plans;
  }

  static _CommonStop? _findCommonStop(
    BusRoute route1,
    BusRoute route2,
    int origIndexOnRoute1,
    int destIndexOnRoute2,
  ) {
    _CommonStop? best;
    for (var i = origIndexOnRoute1 + 1; i < route1.stops.length; i++) {
      for (var j = 0; j < destIndexOnRoute2; j++) {
        if (_stopNameMatch(route1.stops[i].name, route2.stops[j].name)) {
          if (best == null || i < best.index1) {
            best = _CommonStop(index1: i, index2: j);
          }
        }
      }
    }
    return best;
  }

  static bool _stopNameMatch(String a, String b) {
    if (a == b) return true;
    final na = a.toLowerCase().replaceAll(RegExp(r'[\s\-]'), '');
    final nb = b.toLowerCase().replaceAll(RegExp(r'[\s\-]'), '');
    return na == nb;
  }

  static JourneyLeg? _createLeg(BusRoute route, int fromIndex, int toIndex) {
    if (fromIndex >= toIndex) return null;

    final distance = route.getDistanceBetween(fromIndex, toIndex);
    if (distance == null || distance <= 0) return null;

    final preComputedFare = route.getFare(fromIndex, toIndex);
    final fare = preComputedFare ?? calculateDhakaBusFare(distance).toDouble();

    final traffic = EtaService.getTrafficInfo();
    final estMinutes = EtaService.estimateBusMinutes(distance);
    final travelStops = route.stops
        .sublist(fromIndex, toIndex + 1)
        .map((s) => s.name)
        .toList();

    return JourneyLeg(
      route: route,
      boardStopIndex: fromIndex,
      alightStopIndex: toIndex,
      fare: fare,
      stopCount: toIndex - fromIndex,
      distanceKm: distance,
      estimatedMinutes: estMinutes,
      trafficLevel: traffic.level,
      travelStops: travelStops,
    );
  }

  static WalkDirection _getWalkDirection(String dirLabel) {
    if (dirLabel.contains('উত্তর-পূর্ব')) return WalkDirection.northeast;
    if (dirLabel.contains('উত্তর-পশ্চিম')) return WalkDirection.northwest;
    if (dirLabel.contains('দক্ষিণ-পূর্ব')) return WalkDirection.southeast;
    if (dirLabel.contains('দক্ষিণ-পশ্চিম')) return WalkDirection.southwest;
    if (dirLabel.contains('উত্তর')) return WalkDirection.north;
    if (dirLabel.contains('দক্ষিণ')) return WalkDirection.south;
    if (dirLabel.contains('পূর্ব')) return WalkDirection.east;
    if (dirLabel.contains('পশ্চিম')) return WalkDirection.west;
    return WalkDirection.north;
  }

  static List<JourneyPlan> planFromText({
    required String originText,
    required String destText,
    required double? userLat,
    required double? userLng,
    double? destLat,
    double? destLng,
  }) {
    _buildIndex();
    final originCoord = StopCoordinates.find(originText);
    final destCoord = StopCoordinates.find(destText);

    double originLat, originLng, destLatitude, destLongitude;
    String originName, destName;

    if (originCoord != null) {
      originLat = originCoord.lat;
      originLng = originCoord.lng;
      originName = originCoord.nameBn;
    } else if (userLat != null && userLng != null) {
      originLat = userLat;
      originLng = userLng;
      originName = originText;
    } else {
      return [];
    }

    if (destCoord != null) {
      destLatitude = destCoord.lat;
      destLongitude = destCoord.lng;
      destName = destCoord.nameBn;
    } else if (destLat != null && destLng != null) {
      destLatitude = destLat;
      destLongitude = destLng;
      destName = destText;
    } else {
      return [];
    }

    return planJourney(
      originLat: originLat,
      originLng: originLng,
      destLat: destLatitude,
      destLng: destLongitude,
      originName: originName,
      destName: destName,
    );
  }
}

class _RouteStopInfo {
  final BusRoute route;
  final int index;

  const _RouteStopInfo({required this.route, required this.index});
}

class _CommonStop {
  final int index1;
  final int index2;

  const _CommonStop({required this.index1, required this.index2});
}
