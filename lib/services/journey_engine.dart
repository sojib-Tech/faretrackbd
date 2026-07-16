import '../core/utils/fare_calculator.dart';
import '../data/bus_route_data.dart';
import '../data/stop_coordinates.dart';
import '../models/bus_route.dart';
import '../models/journey/journey_plan.dart';
import '../models/journey/journey_result.dart';
import '../services/eta_service.dart';
import '../services/nearest_stop_service.dart';
import '../services/scoring_service.dart';

class JourneyEngine {
  JourneyEngine._();

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

  static BusSegment? _createBusSegment(
    BusRoute route,
    int fromIndex,
    int toIndex,
  ) {
    if (fromIndex >= toIndex) return null;

    final distance = route.getDistanceBetween(fromIndex, toIndex);
    if (distance == null || distance <= 0) return null;

    final preComputedFare = route.getFare(fromIndex, toIndex);
    final fare = preComputedFare ?? calculateDhakaBusFare(distance).toDouble();

    final traffic = EtaService.getTrafficInfo();
    final travelTime = EtaService.estimateBusMinutes(distance);
    final travelStops = route.stops
        .sublist(fromIndex, toIndex + 1)
        .map((s) => s.name)
        .toList();

    return BusSegment(
      busNameEn: route.nameEn,
      busNameBn: route.nameBn,
      boardStop: route.stops[fromIndex].name,
      alightStop: route.stops[toIndex].name,
      boardStopIndex: fromIndex,
      alightStopIndex: toIndex,
      fare: fare,
      distanceKm: distance,
      travelTimeMinutes: travelTime,
      stopCount: toIndex - fromIndex,
      trafficLevel: traffic.level,
      isAc: route.nameBn.contains('AC') || route.nameEn.toLowerCase().contains('ac'),
      travelStops: travelStops,
      route: route,
    );
  }

  static WalkingSegment _createWalkSegment({
    required double distanceMeters,
    required double walkingTimeMinutes,
    required String directionLabel,
    required String fromLabel,
    required String toLabel,
  }) {
    return WalkingSegment(
      distanceMeters: distanceMeters,
      durationMinutes: walkingTimeMinutes,
      direction: _parseWalkDirection(directionLabel),
      fromLabel: fromLabel,
      toLabel: toLabel,
    );
  }

  static WalkDirection _parseWalkDirection(String dirLabel) {
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

  static _CommonStop? _findBestCommonStop(
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

  static List<JourneyResult> findRoutes({
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

    final results = <JourneyResult>[];
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
              final busSeg = _createBusSegment(
                origInfo.route,
                origInfo.index,
                destInfo.index,
              );
              if (busSeg == null) continue;

              final walkToStop = _createWalkSegment(
                distanceMeters: origStop.distanceMeters,
                walkingTimeMinutes: origStop.walkingTimeMinutes,
                directionLabel: origStop.direction,
                fromLabel: originName,
                toLabel: origStop.coordinate.nameBn,
              );

              final walkFromStop = _createWalkSegment(
                distanceMeters: destStop.distanceMeters,
                walkingTimeMinutes: destStop.walkingTimeMinutes,
                directionLabel: destStop.direction,
                fromLabel: destStop.coordinate.nameBn,
                toLabel: destName,
              );

              final result = JourneyResult(
                id: 'plan_${++planId}',
                originName: originName,
                destName: destName,
                segments: [walkToStop, busSeg, walkFromStop],
              ).validate();

              results.add(result);
            }
          }
        }
      }
    }

    if (results.isEmpty) {
      results.addAll(_findTransferRoutes(
        nearbyOrigin: nearbyOrigin.take(3).toList(),
        nearbyDest: nearbyDest.take(3).toList(),
        originName: originName,
        destName: destName,
        planIdStart: planId,
      ));
    }

    final ranked = ScoringService.rankResults(results);
    for (final r in ranked) {
      r.debugLog();
    }
    return ranked;
  }

  static List<JourneyResult> _findTransferRoutes({
    required List<NearbyStop> nearbyOrigin,
    required List<NearbyStop> nearbyDest,
    required String originName,
    required String destName,
    required int planIdStart,
  }) {
    final results = <JourneyResult>[];
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

            final commonStop = _findBestCommonStop(
              origInfo.route,
              destInfo.route,
              origInfo.index,
              destInfo.index,
            );
            if (commonStop == null) continue;

            final busSeg1 = _createBusSegment(
              origInfo.route,
              origInfo.index,
              commonStop.index1,
            );
            final busSeg2 = _createBusSegment(
              destInfo.route,
              commonStop.index2,
              destInfo.index,
            );
            if (busSeg1 == null || busSeg2 == null) continue;

            final walkToStop = _createWalkSegment(
              distanceMeters: origStop.distanceMeters,
              walkingTimeMinutes: origStop.walkingTimeMinutes,
              directionLabel: origStop.direction,
              fromLabel: originName,
              toLabel: origStop.coordinate.nameBn,
            );

            final walkFromStop = _createWalkSegment(
              distanceMeters: destStop.distanceMeters,
              walkingTimeMinutes: destStop.walkingTimeMinutes,
              directionLabel: destStop.direction,
              fromLabel: destStop.coordinate.nameBn,
              toLabel: destName,
            );

            final transfer = TransferSegment(
              fromStop: busSeg1.alightStop,
              toStop: busSeg2.boardStop,
              nextBusNameBn: busSeg2.busNameBn,
              waitTimeMinutes: EtaService.estimateTransferWait(),
            );

            final result = JourneyResult(
              id: 'plan_${++planId}',
              originName: originName,
              destName: destName,
              segments: [walkToStop, busSeg1, transfer, busSeg2, walkFromStop],
            ).validate();

            results.add(result);
          }
        }
      }
    }

    return results;
  }

  static List<JourneyResult> planFromText({
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

    double originLatitude, originLongitude;
    double destLatitude, destLongitude;
    String resolvedOriginName, resolvedDestName;

    if (originCoord != null) {
      originLatitude = originCoord.lat;
      originLongitude = originCoord.lng;
      resolvedOriginName = originCoord.nameBn;
    } else if (userLat != null && userLng != null) {
      originLatitude = userLat;
      originLongitude = userLng;
      resolvedOriginName = originText;
    } else {
      return [];
    }

    if (destCoord != null) {
      destLatitude = destCoord.lat;
      destLongitude = destCoord.lng;
      resolvedDestName = destCoord.nameBn;
    } else if (destLat != null && destLng != null) {
      destLatitude = destLat;
      destLongitude = destLng;
      resolvedDestName = destText;
    } else {
      return [];
    }

    return findRoutes(
      originLat: originLatitude,
      originLng: originLongitude,
      destLat: destLatitude,
      destLng: destLongitude,
      originName: resolvedOriginName,
      destName: resolvedDestName,
    );
  }

  static JourneyResult convertLegacyPlan(dynamic plan) {
    final p = plan as JourneyPlan;
    final segments = <JourneySegment>[];

    segments.add(WalkingSegment(
      distanceMeters: p.initialWalk.distanceMeters,
      durationMinutes: p.initialWalk.durationMinutes,
      direction: p.initialWalk.direction,
      fromLabel: p.initialWalk.fromLabel,
      toLabel: p.initialWalk.toLabel,
    ));

    for (var i = 0; i < p.legs.length; i++) {
      final leg = p.legs[i];
      segments.add(BusSegment(
        busNameEn: leg.route.nameEn,
        busNameBn: leg.route.nameBn,
        boardStop: leg.boardStopName,
        alightStop: leg.alightStopName,
        boardStopIndex: leg.boardStopIndex,
        alightStopIndex: leg.alightStopIndex,
        fare: leg.fare,
        distanceKm: leg.distanceKm,
        travelTimeMinutes: leg.estimatedMinutes,
        stopCount: leg.stopCount,
        trafficLevel: leg.trafficLevel,
        isAc: leg.isAc,
        travelStops: leg.travelStops,
        route: leg.route,
      ));

      if (i < p.legs.length - 1) {
        segments.add(TransferSegment(
          fromStop: leg.alightStopName,
          toStop: p.legs[i + 1].boardStopName,
          nextBusNameBn: p.legs[i + 1].route.nameBn,
          waitTimeMinutes: EtaService.estimateTransferWait(),
        ));
      }
    }

    segments.add(WalkingSegment(
      distanceMeters: p.finalWalk.distanceMeters,
      durationMinutes: p.finalWalk.durationMinutes,
      direction: p.finalWalk.direction,
      fromLabel: p.finalWalk.fromLabel,
      toLabel: p.finalWalk.toLabel,
    ));

    return JourneyResult(
      id: p.id,
      originName: p.initialWalk.fromLabel,
      destName: p.finalWalk.toLabel,
      segments: segments,
      smartScore: p.smartScore,
    ).validate();
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
