import '../bus_route.dart';

enum WalkDirection { north, south, east, west, northeast, northwest, southeast, southwest }

enum TrafficLevel { low, moderate, heavy, closed, accident, construction }

enum RoutePreference { recommended, fastest, cheapest, leastWalking, fewestTransfers }

class WalkSegment {
  final double distanceMeters;
  final double durationMinutes;
  final WalkDirection direction;
  final String fromLabel;
  final String toLabel;

  const WalkSegment({
    required this.distanceMeters,
    required this.durationMinutes,
    required this.direction,
    required this.fromLabel,
    required this.toLabel,
  });

  String get directionLabel {
    switch (direction) {
      case WalkDirection.north: return 'উত্তর';
      case WalkDirection.south: return 'দক্ষিণ';
      case WalkDirection.east: return 'পূর্ব';
      case WalkDirection.west: return 'পশ্চিম';
      case WalkDirection.northeast: return 'উত্তর-পূর্ব';
      case WalkDirection.northwest: return 'উত্তর-পশ্চিম';
      case WalkDirection.southeast: return 'দক্ষিণ-পূর্ব';
      case WalkDirection.southwest: return 'দক্ষিণ-পশ্চিম';
    }
  }
}

enum JourneyStepType { walkToStop, boardBus, rideBus, transfer, walkToDestination, arrive }

class JourneyStep {
  final JourneyStepType type;
  final String? busName;
  final String? busNameBn;
  final String? fromStop;
  final String? toStop;
  final WalkSegment? walkSegment;
  final int? stopCount;
  final double? fare;
  final bool isAc;

  const JourneyStep({
    required this.type,
    this.busName,
    this.busNameBn,
    this.fromStop,
    this.toStop,
    this.walkSegment,
    this.stopCount,
    this.fare,
    this.isAc = false,
  });
}

class JourneyLeg {
  final BusRoute route;
  final int boardStopIndex;
  final int alightStopIndex;
  final double fare;
  final int stopCount;
  final double distanceKm;
  final double estimatedMinutes;
  final TrafficLevel trafficLevel;
  final List<String> travelStops;

  const JourneyLeg({
    required this.route,
    required this.boardStopIndex,
    required this.alightStopIndex,
    required this.fare,
    required this.stopCount,
    required this.distanceKm,
    required this.estimatedMinutes,
    this.trafficLevel = TrafficLevel.moderate,
    required this.travelStops,
  });

  String get boardStopName => route.stops[boardStopIndex].name;
  String get alightStopName => route.stops[alightStopIndex].name;
  bool get isAc => route.nameBn.contains('AC') || route.nameBn.contains('ac') || route.nameEn.toLowerCase().contains('ac');
}

class JourneyPlan {
  final String id;
  final List<JourneyLeg> legs;
  final WalkSegment initialWalk;
  final WalkSegment finalWalk;
  final double totalFare;
  final double totalWalkDistanceMeters;
  final double totalWalkMinutes;
  final double totalBusMinutes;
  final double totalTransferWaitMinutes;
  final double totalETA;
  final double smartScore;
  final RoutePreference preference;
  final int transferCount;

  const JourneyPlan({
    required this.id,
    required this.legs,
    required this.initialWalk,
    required this.finalWalk,
    required this.totalFare,
    required this.totalWalkDistanceMeters,
    required this.totalWalkMinutes,
    required this.totalBusMinutes,
    required this.totalTransferWaitMinutes,
    required this.totalETA,
    required this.smartScore,
    required this.preference,
    required this.transferCount,
  });

  bool get isDirect => legs.length == 1 && transferCount == 0;

  double get totalDistanceKm {
    double busDist = 0;
    for (final leg in legs) {
      busDist += leg.distanceKm;
    }
    return busDist + totalWalkDistanceMeters / 1000;
  }

  double get totalBusDistanceKm {
    double d = 0;
    for (final leg in legs) {
      d += leg.distanceKm;
    }
    return d;
  }

  String get totalDistanceFormatted {
    final km = totalDistanceKm;
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)}মি';
    return '${km.toStringAsFixed(1)} কিমি';
  }

  List<JourneyStep> get steps {
    final result = <JourneyStep>[];

    if (initialWalk.distanceMeters > 0) {
      result.add(JourneyStep(
        type: JourneyStepType.walkToStop,
        walkSegment: initialWalk,
        fromStop: initialWalk.fromLabel,
        toStop: initialWalk.toLabel,
      ));
    }

    for (var i = 0; i < legs.length; i++) {
      final leg = legs[i];
      result.add(JourneyStep(
        type: JourneyStepType.boardBus,
        busName: leg.route.nameEn,
        busNameBn: leg.route.nameBn,
        fromStop: leg.boardStopName,
      ));

      result.add(JourneyStep(
        type: JourneyStepType.rideBus,
        busName: leg.route.nameEn,
        busNameBn: leg.route.nameBn,
        fromStop: leg.boardStopName,
        toStop: leg.alightStopName,
        stopCount: leg.stopCount,
        fare: leg.fare,
        isAc: leg.isAc,
      ));

      if (i < legs.length - 1) {
        final nextLeg = legs[i + 1];
        result.add(JourneyStep(
          type: JourneyStepType.transfer,
          fromStop: leg.alightStopName,
          toStop: nextLeg.boardStopName,
          busName: nextLeg.route.nameEn,
          busNameBn: nextLeg.route.nameBn,
        ));
      }
    }

    if (finalWalk.distanceMeters > 0) {
      result.add(JourneyStep(
        type: JourneyStepType.walkToDestination,
        walkSegment: finalWalk,
        fromStop: finalWalk.fromLabel,
        toStop: finalWalk.toLabel,
      ));
    }

    result.add(const JourneyStep(type: JourneyStepType.arrive));

    return result;
  }

  String get totalETAFormatted {
    final h = totalETA.floor() ~/ 60;
    final m = totalETA.floor() % 60;
    if (h > 0) return '$hঘ $mমি';
    return '$mমি';
  }
}
