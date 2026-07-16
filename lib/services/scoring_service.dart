import '../models/journey/journey_plan.dart';
import '../models/journey/journey_result.dart';

class ScoredOption {
  final JourneyPlan plan;
  final double timeScore;
  final double trafficScore;
  final double fareScore;
  final double walkScore;
  final double transferScore;
  final double reliabilityScore;
  final double totalScore;

  const ScoredOption({
    required this.plan,
    required this.timeScore,
    required this.trafficScore,
    required this.fareScore,
    required this.walkScore,
    required this.transferScore,
    required this.reliabilityScore,
    required this.totalScore,
  });
}

class ScoringService {
  static const double _timeWeight = 0.40;
  static const double _trafficWeight = 0.25;
  static const double _fareWeight = 0.15;
  static const double _walkWeight = 0.10;
  static const double _transferWeight = 0.05;
  static const double _reliabilityWeight = 0.05;

  static List<JourneyPlan> rank(List<JourneyPlan> plans) {
    if (plans.isEmpty) return [];

    final maxTime = plans.map((p) => p.totalETA).reduce((a, b) => a > b ? a : b);
    final maxFare = plans.map((p) => p.totalFare).reduce((a, b) => a > b ? a : b);
    final maxWalk = plans.map((p) => p.totalWalkDistanceMeters).reduce((a, b) => a > b ? a : b);
    final maxTransfer = plans.map((p) => p.transferCount.toDouble()).reduce((a, b) => a > b ? a : b);

    final scored = plans.map((plan) {
      final timeScore = (maxTime > 0 ? (1 - plan.totalETA / maxTime) * 100 : 100).toDouble();
      final trafficScore = _trafficScore(plan);
      final fareScore = (maxFare > 0 ? (1 - plan.totalFare / maxFare) * 100 : 100).toDouble();
      final walkScore = (maxWalk > 0 ? (1 - plan.totalWalkDistanceMeters / maxWalk) * 100 : 100).toDouble();
      final transferScore = (maxTransfer > 0 ? (1 - plan.transferCount / maxTransfer) * 100 : 100).toDouble();
      final reliabilityScore = _reliabilityScore(plan);

      final totalScore = timeScore * _timeWeight +
          trafficScore * _trafficWeight +
          fareScore * _fareWeight +
          walkScore * _walkWeight +
          transferScore * _transferWeight +
          reliabilityScore * _reliabilityWeight;

      return ScoredOption(
        plan: plan,
        timeScore: timeScore,
        trafficScore: trafficScore,
        fareScore: fareScore,
        walkScore: walkScore,
        transferScore: transferScore,
        reliabilityScore: reliabilityScore,
        totalScore: totalScore,
      );
    }).toList();

    scored.sort((a, b) => b.totalScore.compareTo(a.totalScore));

    return scored.map((s) {
      final p = s.plan;
      return JourneyPlan(
        id: p.id,
        legs: p.legs,
        initialWalk: p.initialWalk,
        finalWalk: p.finalWalk,
        totalFare: p.totalFare,
        totalWalkDistanceMeters: p.totalWalkDistanceMeters,
        totalWalkMinutes: p.totalWalkMinutes,
        totalBusMinutes: p.totalBusMinutes,
        totalTransferWaitMinutes: p.totalTransferWaitMinutes,
        totalETA: p.totalETA,
        smartScore: s.totalScore,
        preference: p.preference,
        transferCount: p.transferCount,
      );
    }).toList();
  }

  static double _trafficScore(JourneyPlan plan) {
    double score = 100;
    for (final leg in plan.legs) {
      switch (leg.trafficLevel) {
        case TrafficLevel.low:
          break;
        case TrafficLevel.moderate:
          score -= 10;
          break;
        case TrafficLevel.heavy:
          score -= 30;
          break;
        case TrafficLevel.closed:
        case TrafficLevel.accident:
        case TrafficLevel.construction:
          score -= 60;
          break;
      }
    }
    return score.clamp(0, 100).toDouble();
  }

  static double _reliabilityScore(JourneyPlan plan) {
    if (plan.isDirect) return 90;
    if (plan.transferCount == 1) return 70;
    return 50;
  }

  static List<JourneyResult> rankResults(List<JourneyResult> results) {
    if (results.isEmpty) return [];

    final maxTime = results.map((r) => r.totalTimeMinutes).reduce((a, b) => a > b ? a : b);
    final maxFare = results.map((r) => r.totalFare).reduce((a, b) => a > b ? a : b);
    final maxWalk = results.map((r) => r.totalWalkingDistanceMeters).reduce((a, b) => a > b ? a : b);
    final maxTransfer = results.map((r) => r.transferCount.toDouble()).reduce((a, b) => a > b ? a : b);

    final scored = results.map((result) {
      final timeScore = (maxTime > 0 ? (1 - result.totalTimeMinutes / maxTime) * 100 : 100).toDouble();
      final fareScore = (maxFare > 0 ? (1 - result.totalFare / maxFare) * 100 : 100).toDouble();
      final walkScore = (maxWalk > 0 ? (1 - result.totalWalkingDistanceMeters / maxWalk) * 100 : 100).toDouble();
      final transferScore = (maxTransfer > 0 ? (1 - result.transferCount / maxTransfer) * 100 : 100).toDouble();

      final totalScore = timeScore * 0.40 +
          fareScore * 0.25 +
          walkScore * 0.20 +
          transferScore * 0.15;

      return _ScoredResult(
        result: result,
        totalScore: totalScore,
      );
    }).toList();

    scored.sort((a, b) => b.totalScore.compareTo(a.totalScore));

    return scored.map((s) => JourneyResult(
      id: s.result.id,
      originName: s.result.originName,
      destName: s.result.destName,
      segments: s.result.segments,
      smartScore: s.totalScore,
    )).toList();
  }
}

class _ScoredResult {
  final JourneyResult result;
  final double totalScore;

  const _ScoredResult({required this.result, required this.totalScore});
}
