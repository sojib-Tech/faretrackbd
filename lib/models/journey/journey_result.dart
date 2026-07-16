import '../bus_route.dart';
import 'journey_plan.dart';
export 'journey_plan.dart' show WalkDirection, TrafficLevel, JourneyStepType;

sealed class JourneySegment {
  const JourneySegment();
}

class WalkingSegment extends JourneySegment {
  final double distanceMeters;
  final double durationMinutes;
  final WalkDirection direction;
  final String fromLabel;
  final String toLabel;

  const WalkingSegment({
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

  double get distanceKm => distanceMeters / 1000.0;
}

class BusSegment extends JourneySegment {
  final String busNameEn;
  final String busNameBn;
  final String boardStop;
  final String alightStop;
  final int boardStopIndex;
  final int alightStopIndex;
  final double fare;
  final double distanceKm;
  final double travelTimeMinutes;
  final int stopCount;
  final TrafficLevel trafficLevel;
  final bool isAc;
  final List<String> travelStops;
  final BusRoute route;

  const BusSegment({
    required this.busNameEn,
    required this.busNameBn,
    required this.boardStop,
    required this.alightStop,
    required this.boardStopIndex,
    required this.alightStopIndex,
    required this.fare,
    required this.distanceKm,
    required this.travelTimeMinutes,
    required this.stopCount,
    required this.trafficLevel,
    required this.isAc,
    required this.travelStops,
    required this.route,
  });
}

class TransferSegment extends JourneySegment {
  final String fromStop;
  final String toStop;
  final String nextBusNameBn;
  final double waitTimeMinutes;

  const TransferSegment({
    required this.fromStop,
    required this.toStop,
    required this.nextBusNameBn,
    required this.waitTimeMinutes,
  });
}

class JourneyStep {
  final JourneyStepType type;
  final String? busNameEn;
  final String? busNameBn;
  final String? fromStop;
  final String? toStop;
  final WalkingSegment? walkSegment;
  final BusSegment? busSegment;
  final int? stopCount;
  final double? fare;
  final bool isAc;

  const JourneyStep({
    required this.type,
    this.busNameEn,
    this.busNameBn,
    this.fromStop,
    this.toStop,
    this.walkSegment,
    this.busSegment,
    this.stopCount,
    this.fare,
    this.isAc = false,
  });
}

class JourneyResult {
  final String id;
  final String originName;
  final String destName;
  final List<JourneySegment> segments;
  final double smartScore;

  const JourneyResult({
    required this.id,
    required this.originName,
    required this.destName,
    required this.segments,
    this.smartScore = 0,
  });

  List<BusSegment> get busSegments =>
      segments.whereType<BusSegment>().toList();

  List<WalkingSegment> get walkingSegments =>
      segments.whereType<WalkingSegment>().toList();

  List<TransferSegment> get transferSegments =>
      segments.whereType<TransferSegment>().toList();

  int get transferCount => transferSegments.length;

  bool get isDirect => busSegments.length == 1 && transferCount == 0;

  double get totalFare =>
      busSegments.fold(0.0, (sum, seg) => sum + seg.fare);

  double get totalWalkingDistanceMeters =>
      walkingSegments.fold(0.0, (sum, seg) => sum + seg.distanceMeters);

  double get totalWalkingDistanceKm => totalWalkingDistanceMeters / 1000.0;

  double get totalBusDistanceKm =>
      busSegments.fold(0.0, (sum, seg) => sum + seg.distanceKm);

  double get totalDistanceKm => totalBusDistanceKm + totalWalkingDistanceKm;

  double get totalWalkingTimeMinutes =>
      walkingSegments.fold(0.0, (sum, seg) => sum + seg.durationMinutes);

  double get totalBusTravelTimeMinutes =>
      busSegments.fold(0.0, (sum, seg) => sum + seg.travelTimeMinutes);

  double get totalWaitingTimeMinutes =>
      transferSegments.fold(0.0, (sum, seg) => sum + seg.waitTimeMinutes);

  double get totalTimeMinutes =>
      totalWalkingTimeMinutes + totalBusTravelTimeMinutes + totalWaitingTimeMinutes;

  String get totalTimeFormatted {
    final h = totalTimeMinutes.floor() ~/ 60;
    final m = totalTimeMinutes.floor() % 60;
    if (h > 0) return '$hঘ $mমি';
    return '$mমি';
  }

  String get totalDistanceFormatted {
    final km = totalDistanceKm;
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)}মি';
    return '${km.toStringAsFixed(1)} কিমি';
  }

  List<JourneyStep> get steps {
    final result = <JourneyStep>[];
    for (final segment in segments) {
      switch (segment) {
        case WalkingSegment():
          final isToDest = segment == segments.last;
          result.add(JourneyStep(
            type: isToDest ? JourneyStepType.walkToDestination : JourneyStepType.walkToStop,
            walkSegment: segment,
            fromStop: segment.fromLabel,
            toStop: segment.toLabel,
          ));
        case BusSegment():
          result.add(JourneyStep(
            type: JourneyStepType.boardBus,
            busNameEn: segment.busNameEn,
            busNameBn: segment.busNameBn,
            fromStop: segment.boardStop,
          ));
          result.add(JourneyStep(
            type: JourneyStepType.rideBus,
            busNameEn: segment.busNameEn,
            busNameBn: segment.busNameBn,
            fromStop: segment.boardStop,
            toStop: segment.alightStop,
            stopCount: segment.stopCount,
            fare: segment.fare,
            isAc: segment.isAc,
            busSegment: segment,
          ));
        case TransferSegment():
          result.add(JourneyStep(
            type: JourneyStepType.transfer,
            fromStop: segment.fromStop,
            toStop: segment.toStop,
            busNameBn: segment.nextBusNameBn,
          ));
      }
    }
    result.add(const JourneyStep(type: JourneyStepType.arrive));
    return result;
  }

  JourneyResult validate() {
    final expectedFare = busSegments.fold(0.0, (s, b) => s + b.fare);
    assert(
      (totalFare - expectedFare).abs() < 0.01,
      'Fare mismatch: totalFare=$totalFare, sum(busFares)=$expectedFare',
    );

    final expectedBusDist = busSegments.fold(0.0, (s, b) => s + b.distanceKm);
    assert(
      (totalBusDistanceKm - expectedBusDist).abs() < 0.01,
      'Bus distance mismatch',
    );

    final expectedWalkDist = walkingSegments.fold(0.0, (s, w) => s + w.distanceMeters);
    assert(
      (totalWalkingDistanceMeters - expectedWalkDist).abs() < 0.01,
      'Walking distance mismatch',
    );

    final expectedWalkTime = walkingSegments.fold(0.0, (s, w) => s + w.durationMinutes);
    assert(
      (totalWalkingTimeMinutes - expectedWalkTime).abs() < 0.01,
      'Walking time mismatch',
    );

    final expectedBusTime = busSegments.fold(0.0, (s, b) => s + b.travelTimeMinutes);
    assert(
      (totalBusTravelTimeMinutes - expectedBusTime).abs() < 0.01,
      'Bus time mismatch',
    );

    final expectedWaitTime = transferSegments.fold(0.0, (s, t) => s + t.waitTimeMinutes);
    assert(
      (totalWaitingTimeMinutes - expectedWaitTime).abs() < 0.01,
      'Wait time mismatch',
    );

    final expectedTotalTime = totalWalkingTimeMinutes + totalBusTravelTimeMinutes + totalWaitingTimeMinutes;
    assert(
      (totalTimeMinutes - expectedTotalTime).abs() < 0.01,
      'Total time mismatch: totalTime=$totalTimeMinutes, sum=$expectedTotalTime',
    );

    return this;
  }

  void debugLog() {
    // ignore: avoid_print
    print('=== JourneyResult: $id ===');
    // ignore: avoid_print
    print('  Route: $originName → $destName');
    // ignore: avoid_print
    print('  Score: ${smartScore.toStringAsFixed(1)}');
    // ignore: avoid_print
    print('  Segments: ${segments.length} (${busSegments.length} bus, ${walkingSegments.length} walk, ${transferSegments.length} transfer)');
    // ignore: avoid_print
    print('  Total Time: ${totalTimeMinutes.toStringAsFixed(1)} min');
    // ignore: avoid_print
    print('    Walk: ${totalWalkingTimeMinutes.toStringAsFixed(1)} min');
    // ignore: avoid_print
    print('    Bus: ${totalBusTravelTimeMinutes.toStringAsFixed(1)} min');
    // ignore: avoid_print
    print('    Wait: ${totalWaitingTimeMinutes.toStringAsFixed(1)} min');
    // ignore: avoid_print
    print('  Total Distance: ${totalDistanceKm.toStringAsFixed(2)} km');
    // ignore: avoid_print
    print('    Walk: ${totalWalkingDistanceKm.toStringAsFixed(2)} km');
    // ignore: avoid_print
    print('    Bus: ${totalBusDistanceKm.toStringAsFixed(2)} km');
    // ignore: avoid_print
    print('  Total Fare: ৳${totalFare.toStringAsFixed(0)}');
    for (final seg in busSegments) {
      // ignore: avoid_print
      print('    ${seg.busNameBn}: ${seg.boardStop} → ${seg.alightStop} (${seg.distanceKm.toStringAsFixed(1)} km, ৳${seg.fare.toStringAsFixed(0)})');
    }
    // ignore: avoid_print
    print('========================');
  }
}
