import '../models/journey/journey_plan.dart';

class TrafficInfo {
  final TrafficLevel level;
  final double multiplier;
  final String labelBn;

  const TrafficInfo({
    required this.level,
    required this.multiplier,
    required this.labelBn,
  });
}

class EtaService {
  static const double _busSpeedKmh = 20.0;
  static const double _walkSpeedKmh = 5.0;
  static const double _transferWaitMinutes = 5.0;

  static TrafficInfo getTrafficInfo() {
    final hour = DateTime.now().hour;

    if (hour >= 7 && hour < 10) {
      return const TrafficInfo(
        level: TrafficLevel.heavy,
        multiplier: 1.5,
        labelBn: 'ভারী ট্রাফিক',
      );
    } else if (hour >= 10 && hour < 16) {
      return const TrafficInfo(
        level: TrafficLevel.moderate,
        multiplier: 1.2,
        labelBn: 'মাঝারি ট্রাফিক',
      );
    } else if (hour >= 16 && hour < 20) {
      return const TrafficInfo(
        level: TrafficLevel.heavy,
        multiplier: 1.6,
        labelBn: 'ভারী ট্রাফিক',
      );
    } else {
      return const TrafficInfo(
        level: TrafficLevel.low,
        multiplier: 1.0,
        labelBn: 'কম ট্রাফিক',
      );
    }
  }

  static double estimateWalkMinutes(double distanceMeters) {
    return (distanceMeters / 1000.0 / _walkSpeedKmh) * 60.0;
  }

  static double estimateBusMinutes(double distanceKm) {
    final traffic = getTrafficInfo();
    return (distanceKm / _busSpeedKmh) * 60.0 * traffic.multiplier;
  }

  static double estimateTransferWait() => _transferWaitMinutes;

  static double calculateETA({
    required double walkDistanceMeters,
    required double busDistanceKm,
    required int transferCount,
  }) {
    final walkMin = estimateWalkMinutes(walkDistanceMeters);
    final busMin = estimateBusMinutes(busDistanceKm);
    final transferMin = transferCount * _transferWaitMinutes;
    return walkMin + busMin + transferMin;
  }
}
