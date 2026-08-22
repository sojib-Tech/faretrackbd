import 'dart:math';
import '../core/constants/app_constants.dart';
import '../core/utils/fare_calculator.dart';
import '../data/bus_route_data.dart';
import '../data/dhaka_bus_route_data.dart';
import '../data/stop_coordinates.dart';
import '../models/bus_route.dart';
import '../models/journey/journey_plan.dart';
import '../models/journey/journey_result.dart';
import '../models/journey/stop_coordinate.dart';
import '../services/eta_service.dart';
import '../services/journey_planner_engine.dart';
import '../services/nearest_stop_service.dart';
import '../services/scoring_service.dart';

class JourneyEngine {
  JourneyEngine._();

  static final Map<String, List<_RouteStopInfo>> _stopToRoutes = {};
  static bool _indexBuilt = false;

  static Future<void> _buildIndex() async {
    if (_indexBuilt) return;
    _indexBuilt = true;
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

    final jsonBuses = await DhakaBusRouteData.load();
    for (final bus in jsonBuses) {
      if (bus.route.length < 2) continue;
      final jsonRoute = _JsonBusRouteAdapter.fromJson(bus);
      if (_jsonRouteIndexed(jsonRoute.nameEn)) continue;
      for (var i = 0; i < jsonRoute.stops.length; i++) {
        final rawName = jsonRoute.stops[i].name;
        final info = _RouteStopInfo(route: jsonRoute, index: i);
        _stopToRoutes.putIfAbsent(rawName, () => []).add(info);
        final coord = DhakaBusRouteData.findStop(rawName);
        if (coord != null) {
          _stopToRoutes.putIfAbsent(coord.name, () => []).add(info);
          if (coord.nameBn != rawName) {
            _stopToRoutes.putIfAbsent(coord.nameBn, () => []).add(info);
          }
        }
      }
    }
  }

  static bool _jsonRouteIndexed(String nameEn) {
    for (final entries in _stopToRoutes.values) {
      for (final info in entries) {
        if (info.route.nameEn == nameEn) return true;
      }
    }
    return false;
  }

  static double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const earthRadius = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180.0;
    final dLng = (lng2 - lng1) * pi / 180.0;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180.0) * cos(lat2 * pi / 180.0) *
        sin(dLng / 2) * sin(dLng / 2);
    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static String _getWalkDirectionLabel(double lat1, double lng1, double lat2, double lng2) {
    final angle = atan2(lng2 - lng1, lat2 - lat1) * 180 / pi;
    if (angle >= -22.5 && angle < 22.5) return 'উত্তর';
    if (angle >= 22.5 && angle < 67.5) return 'উত্তর-পূর্ব';
    if (angle >= 67.5 && angle < 112.5) return 'পূর্ব';
    if (angle >= 112.5 && angle < 157.5) return 'দক্ষিণ-পূর্ব';
    if (angle >= 157.5 || angle < -157.5) return 'দক্ষিণ';
    if (angle >= -157.5 && angle < -112.5) return 'দক্ষিণ-পশ্চিম';
    if (angle >= -112.5 && angle < -67.5) return 'পশ্চিম';
    return 'উত্তর-পশ্চিম';
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

  static bool _isDuplicate(List<JourneyResult> existing, JourneyResult candidate) {
    for (final e in existing) {
      if (e.busSegments.length != candidate.busSegments.length) continue;
      if (e.transferCount != candidate.transferCount) continue;
      final eSig = e.busSegments.map((s) => '${s.busNameEn}|${s.boardStop}-${s.alightStop}').join(', ');
      final cSig = candidate.busSegments.map((s) => '${s.busNameEn}|${s.boardStop}-${s.alightStop}').join(', ');
      if (eSig == cSig) return true;
    }
    return false;
  }

  static Future<List<JourneyResult>> findRoutes({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required String originName,
    required String destName,
  }) async {
    await _buildIndex();

    final directDistance = _haversine(originLat, originLng, destLat, destLng);

    final walkOnlyTime = directDistance / 1000.0 / AppConstants.walkOnlySpeedKmh * 60.0;

    final nearbyOrigin = NearestStopService.findNearby(
      latitude: originLat,
      longitude: originLng,
      radiusMeters: AppConstants.journeySearchRadiusMeters,
    );

    final nearbyDest = NearestStopService.findNearby(
      latitude: destLat,
      longitude: destLng,
      radiusMeters: AppConstants.journeySearchRadiusMeters,
    );

    final results = <JourneyResult>[];
    var planId = 0;

    if (directDistance <= AppConstants.walkOnlyThresholdMeters) {
      final walkDir = _getWalkDirectionLabel(originLat, originLng, destLat, destLng);
      final walkSeg = _createWalkSegment(
        distanceMeters: directDistance,
        walkingTimeMinutes: walkOnlyTime,
        directionLabel: walkDir,
        fromLabel: originName,
        toLabel: destName,
      );
      results.add(JourneyResult(
        id: 'plan_${++planId}',
        originName: originName,
        destName: destName,
        segments: [walkSeg],
        smartScore: 100,
      ));
      return results;
    }

    if (nearbyOrigin.isEmpty || nearbyDest.isEmpty) {
      return _buildWalkOnlyResult(
        originLat, originLng, destLat, destLng,
        originName, destName, directDistance, walkOnlyTime,
        planId,
      );
    }

    final busResults = _findDirectRoutes(
      nearbyOrigin, nearbyDest, originName, destName, planId,
    );
    planId += busResults.length;
    results.addAll(busResults);

    final transferResults = _findTransferRoutes(
      nearbyOrigin: nearbyOrigin.take(3).toList(),
      nearbyDest: nearbyDest.take(3).toList(),
      originName: originName,
      destName: destName,
      planIdStart: planId,
    );
    planId += transferResults.length;
    results.addAll(transferResults);

    if (results.isEmpty) {
      return _buildWalkOnlyResult(
        originLat, originLng, destLat, destLng,
        originName, destName, directDistance, walkOnlyTime,
        planId,
      );
    }

    final busTimeBest = results
        .map((r) => r.totalTimeMinutes)
        .reduce((a, b) => a < b ? a : b);

    if (walkOnlyTime < busTimeBest) {
      final walkDir = _getWalkDirectionLabel(originLat, originLng, destLat, destLng);
      final walkSeg = _createWalkSegment(
        distanceMeters: directDistance,
        walkingTimeMinutes: walkOnlyTime,
        directionLabel: walkDir,
        fromLabel: originName,
        toLabel: destName,
      );
      results.insert(0, JourneyResult(
        id: 'plan_${++planId}',
        originName: originName,
        destName: destName,
        segments: [walkSeg],
        smartScore: 0,
      ));
    }

    final deduped = <JourneyResult>[];
    for (final r in results) {
      if (!_isDuplicate(deduped, r)) {
        deduped.add(r);
      }
    }

    final ranked = ScoringService.rankResults(deduped);
    final capped = ranked.take(AppConstants.journeyMaxCandidates).toList();

    for (final r in capped) {
      r.debugLog();
    }
    return capped;
  }

  static List<JourneyResult> _buildWalkOnlyResult(
    double originLat, double originLng,
    double destLat, double destLng,
    String originName, String destName,
    double distance, double walkTime,
    int planId,
  ) {
    final walkDir = _getWalkDirectionLabel(originLat, originLng, destLat, destLng);
    final walkSeg = _createWalkSegment(
      distanceMeters: distance,
      walkingTimeMinutes: walkTime,
      directionLabel: walkDir,
      fromLabel: originName,
      toLabel: destName,
    );
    final result = JourneyResult(
      id: 'plan_${++planId}',
      originName: originName,
      destName: destName,
      segments: [walkSeg],
      smartScore: 0,
    );
    return [result];
  }

  static List<JourneyResult> _findDirectRoutes(
    List<NearbyStop> nearbyOrigin,
    List<NearbyStop> nearbyDest,
    String originName,
    String destName,
    int planIdStart,
  ) {
    final results = <JourneyResult>[];
    var planId = planIdStart;

    for (final origStop in nearbyOrigin.take(5)) {
      for (final destStop in nearbyDest.take(5)) {
        final origRoutes = _stopToRoutes[origStop.coordinate.nameBn] ??
            _stopToRoutes[origStop.coordinate.name] ?? [];
        final destRoutes = _stopToRoutes[destStop.coordinate.nameBn] ??
            _stopToRoutes[destStop.coordinate.name] ?? [];

        for (final origInfo in origRoutes) {
          for (final destInfo in destRoutes) {
            if (origInfo.route.id == destInfo.route.id &&
                origInfo.index != destInfo.index) {
              final boardIdx = origInfo.index < destInfo.index
                  ? origInfo.index : destInfo.index;
              final alightIdx = origInfo.index < destInfo.index
                  ? destInfo.index : origInfo.index;
              final busSeg = _createBusSegment(
                origInfo.route,
                boardIdx,
                alightIdx,
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

    return results;
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

            final transferFromCoord = StopCoordinates.find(
              origInfo.route.stops[commonStop.index1].name,
            );
            final transferToCoord = StopCoordinates.find(
              destInfo.route.stops[commonStop.index2].name,
            );
            if (transferFromCoord != null && transferToCoord != null) {
              final transferWalkDist = _haversine(
                transferFromCoord.lat, transferFromCoord.lng,
                transferToCoord.lat, transferToCoord.lng,
              );
              if (transferWalkDist > AppConstants.journeyTransferMaxWalkMeters) {
                continue;
              }
            }

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

  static Future<List<JourneyResult>> planFromText({
    required String originText,
    required String destText,
    required double? userLat,
    required double? userLng,
    double? destLat,
    double? destLng,
  }) async {
    await _buildIndex();
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

    return await findRoutes(
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

class _JsonBusRouteAdapter extends BusRoute {
  _JsonBusRouteAdapter._({
    required super.id,
    required super.nameBn,
    required super.nameEn,
    required super.routeNo,
    required super.totalDistanceKm,
    required super.stops,
    required super.fareData,
  });

  static BusRoute fromJson(DhakaBusRoute json) {
    final resolved = <_ResolvedCoord>[];
    double cumulative = 0;
    for (final name in json.route) {
      final coord = DhakaBusRouteData.findStop(name);
      if (coord != null && resolved.isNotEmpty) {
        final prev = resolved.last.coord;
        if (prev != null) {
          cumulative += JourneyPlannerEngine.haversine(
            prev.lat, prev.lng, coord.lat, coord.lng,
          ) / 1000.0;
        }
      }
      resolved.add(_ResolvedCoord(coord: coord, cumDist: cumulative));
    }

    final stops = json.route.asMap().entries.map((e) {
      return BusStop(
        name: e.value,
        distanceFromStartKm: resolved[e.key].cumDist,
      );
    }).toList();

    final n = stops.length;
    final fareData = <List<double>>[];
    for (var i = 0; i < n; i++) {
      final row = <double>[];
      for (var j = 0; j < i; j++) {
        final dist = (resolved[i].cumDist - resolved[j].cumDist).abs();
        row.add(calculateDhakaBusFare(dist).toDouble());
      }
      fareData.add(row);
    }

    return _JsonBusRouteAdapter._(
      id: 'json_${json.nameEn}',
      nameBn: json.nameBn,
      nameEn: json.nameEn,
      routeNo: '',
      totalDistanceKm: cumulative,
      stops: stops,
      fareData: fareData,
    );
  }
}

class _ResolvedCoord {
  final StopCoordinate? coord;
  final double cumDist;
  const _ResolvedCoord({this.coord, this.cumDist = 0});
}
