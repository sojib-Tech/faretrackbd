import '../data/dhaka_bus_route_data.dart';
import '../models/journey/stop_coordinate.dart';
import 'journey_planner_engine.dart';

class CorridorBusResult {
  final String nameEn;
  final String nameBn;
  final double distanceKm;
  final double fare;
  final int originIndex;
  final int destIndex;
  final int stopsBetween;
  final StopCoordinate? originStop;
  final StopCoordinate? destStop;
  final String? type;
  final bool isAc;

  const CorridorBusResult({
    required this.nameEn,
    required this.nameBn,
    required this.distanceKm,
    required this.fare,
    required this.originIndex,
    required this.destIndex,
    required this.stopsBetween,
    this.originStop,
    this.destStop,
    this.type,
    this.isAc = false,
  });
}

class CorridorBusService {
  CorridorBusService._();

  static Future<List<CorridorBusResult>> findBuses({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String? originHint,
    String? destHint,
  }) async {
    final buses = await DhakaBusRouteData.load();
    final engine = JourneyPlannerEngine.createFromBuses(buses);

    final candidates = engine.findDirectCandidates(
      originLat: originLat,
      originLng: originLng,
      destLat: destLat,
      destLng: destLng,
    );

    return candidates.map((c) {
      final isAc = c.bus.isAc;
      final resolvedOriginIdx = c.originStop.routeIndex;
      final resolvedDestIdx = c.destStop.routeIndex;
      final low = resolvedOriginIdx < resolvedDestIdx ? resolvedOriginIdx : resolvedDestIdx;
      final high = resolvedOriginIdx < resolvedDestIdx ? resolvedDestIdx : resolvedOriginIdx;

      return CorridorBusResult(
        nameEn: c.bus.nameEn,
        nameBn: c.bus.nameBn,
        distanceKm: double.parse(c.distanceKm.toStringAsFixed(1)),
        fare: c.fare,
        originIndex: low,
        destIndex: high,
        stopsBetween: high - low - 1,
        originStop: c.originStop.coordinate,
        destStop: c.destStop.coordinate,
        type: c.bus.type,
        isAc: isAc,
      );
    }).toList();
  }
}
