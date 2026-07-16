import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/journey/journey_result.dart';
import '../../../providers/journey_planner_provider.dart';
import 'journey_map_screen.dart';

class JourneyDetailScreen extends ConsumerWidget {
  const JourneyDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(journeyPlannerProvider);
    final result = state.selectedResult;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('যাত্রা বিবরণ')),
        body: const Center(child: Text('কোনো পরিকল্পনা নির্বাচন করুন')),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppConstants.backgroundDark : AppConstants.paper,
      appBar: AppBar(
        title: const Text('যাত্রা বিবরণ',
            style: TextStyle(fontFamily: AppConstants.fontBengali)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(context, result, state, isDark),
            const SizedBox(height: 20),
            _buildTimelineHeader(isDark),
            const SizedBox(height: 8),
            _buildTimeline(result, isDark),
            const SizedBox(height: 20),
            _buildFareBreakdown(result, isDark),
            const SizedBox(height: 20),
            _buildTrafficInfo(state, isDark),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, JourneyResult result, JourneyPlannerState state, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A3A2A), const Color(0xFF122A1E)]
              : [AppConstants.primaryGreen, AppConstants.pineDeep],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryGreen.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.isDirect ? 'সরাসরি বাস' : '${result.transferCount}টি সংযোগ',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppConstants.fontBengali,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'স্কোর: ${result.smartScore.toStringAsFixed(0)}/100',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontFamily: AppConstants.fontBengali,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _summaryStat(Icons.access_time_rounded, 'সময়', result.totalTimeFormatted),
              const SizedBox(width: 20),
              _summaryStat(Icons.payments_outlined, 'ভাড়া', '৳${result.totalFare.toStringAsFixed(0)}'),
              const SizedBox(width: 20),
              _summaryStat(Icons.straighten_rounded, 'দূরত্ব', result.totalDistanceFormatted),
              const SizedBox(width: 20),
              _summaryStat(Icons.directions_walk_rounded, 'হাঁটা',
                  '${result.totalWalkingDistanceMeters.toStringAsFixed(0)}মি'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => JourneyMapScreen(result: result),
                  ),
                );
              },
              icon: const Icon(Icons.map_rounded, size: 18),
              label: const Text(
                'মানচিত্রে দেখুন',
                style: TextStyle(
                  fontFamily: AppConstants.fontBengali,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: Colors.white60),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(
              fontSize: 11, color: Colors.white60,
              fontFamily: AppConstants.fontBengali,
            )),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          fontFamily: AppConstants.fontBengali,
        )),
      ],
    );
  }

  Widget _buildTimelineHeader(bool isDark) {
    return Text(
      'যাত্রার ধাপ',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        fontFamily: AppConstants.fontBengali,
        color: isDark ? Colors.white : AppConstants.ink,
      ),
    );
  }

  Widget _buildTimeline(JourneyResult result, bool isDark) {
    final steps = result.steps;

    return Column(
      children: List.generate(steps.length, (i) {
        final step = steps[i];
        final isFirst = i == 0;
        final isLast = i == steps.length - 1;

        return _buildTimelineItem(step, isFirst, isLast, isDark);
      }),
    );
  }

  Widget _buildTimelineItem(
      JourneyStep step, bool isFirst, bool isLast, bool isDark) {
    late Color dotColor;
    Widget content;

    switch (step.type) {
      case JourneyStepType.walkToStop:
        dotColor = AppConstants.fareAmber;
        content = _buildWalkStep(step, isDark);
        break;
      case JourneyStepType.boardBus:
        dotColor = AppConstants.primaryGreen;
        content = _buildBoardStep(step, isDark);
        break;
      case JourneyStepType.rideBus:
        dotColor = AppConstants.primaryAccent;
        content = _buildRideStep(step, isDark);
        break;
      case JourneyStepType.transfer:
        dotColor = AppConstants.fareAmber;
        content = _buildTransferStep(step, isDark);
        break;
      case JourneyStepType.walkToDestination:
        dotColor = AppConstants.fareAmber;
        content = _buildWalkStep(step, isDark);
        break;
      case JourneyStepType.arrive:
        dotColor = AppConstants.successGreen;
        content = _buildArriveStep(isDark);
        break;
    }

    final showLine = !isLast;
    final lineColor = isDark ? Colors.white12 : AppConstants.cardLine;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: isFirst || isLast ? 16 : 12,
                  height: isFirst || isLast ? 16 : 12,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: isFirst || isLast
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                    boxShadow: isFirst || isLast
                        ? [BoxShadow(color: dotColor.withValues(alpha: 0.4), blurRadius: 6)]
                        : [],
                  ),
                  child: isFirst
                      ? const Icon(Icons.circle, size: 6, color: Colors.white)
                      : isLast
                          ? const Icon(Icons.check, size: 8, color: Colors.white)
                          : null,
                ),
                if (showLine)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildWalkStep(JourneyStep step, bool isDark) {
    final walk = step.walkSegment;
    if (walk == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.fareAmber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.fareAmber.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_walk_rounded,
              size: 20, color: AppConstants.fareAmber),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'হাঁটুন ${walk.distanceMeters.toStringAsFixed(0)}মি',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppConstants.fontBengali,
                  ),
                ),
                Text(
                  '${walk.fromLabel} → ${walk.toLabel} · ${walk.directionLabel} · ~${walk.durationMinutes.toStringAsFixed(0)} মিনিট',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontFamily: AppConstants.fontBengali,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildBoardStep(JourneyStep step, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.login_rounded, size: 18, color: AppConstants.primaryGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${step.busNameBn ?? step.busNameEn ?? ''} -এ উঠুন',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppConstants.fontBengali,
                  ),
                ),
                Text(
                  'স্টপ: ${step.fromStop ?? ''}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontFamily: AppConstants.fontBengali,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildRideStep(JourneyStep step, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.primaryAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_bus_rounded,
                  size: 18, color: AppConstants.primaryAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${step.fromStop ?? ''} → ${step.toStop ?? ''}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppConstants.fontBengali,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Row(
              children: [
                _chipTag('${step.stopCount ?? 0} স্টপ',
                    AppConstants.primaryAccent, isDark),
                const SizedBox(width: 8),
                if (step.fare != null)
                  _chipTag('৳${step.fare!.toStringAsFixed(0)}',
                      AppConstants.fareAmber, isDark),
                if (step.isAc) ...[
                  const SizedBox(width: 8),
                  _chipTag('AC', AppConstants.primaryAccent, isDark),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildTransferStep(JourneyStep step, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.fareAmber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.fareAmber.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.transfer_within_a_station_rounded,
              size: 18, color: AppConstants.fareAmber),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${step.fromStop ?? ''}-এ নামুন',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppConstants.fontBengali,
                  ),
                ),
                Text(
                  '${step.busNameBn ?? ''}-এ উঠুন',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontFamily: AppConstants.fontBengali,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildArriveStep(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.successGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.successGreen.withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.flag_rounded, size: 18, color: AppConstants.successGreen),
          SizedBox(width: 10),
          Text(
            'গন্তব্যে পৌঁছেছেন!',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: AppConstants.fontBengali,
              color: AppConstants.successGreen,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _chipTag(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
          fontFamily: AppConstants.fontBengali,
        ),
      ),
    );
  }

  Widget _buildFareBreakdown(JourneyResult result, bool isDark) {
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : AppConstants.cardLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ভাড়া বিবরণ',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: AppConstants.fontBengali,
              color: isDark ? Colors.white : AppConstants.ink,
            ),
          ),
          const SizedBox(height: 12),
          ...result.busSegments.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(
                  'বাস ${e.key + 1}: ${e.value.busNameBn}',
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: AppConstants.fontBengali,
                    color: isDark ? Colors.white70 : AppConstants.ink,
                  ),
                ),
                const Spacer(),
                Text(
                  '৳${e.value.fare.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.primaryGreen,
                  ),
                ),
              ],
            ),
          )),
          Divider(color: isDark ? Colors.white12 : AppConstants.cardLine),
          Row(
            children: [
              Text(
                'মোট',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppConstants.fontBengali,
                  color: isDark ? Colors.white : AppConstants.ink,
                ),
              ),
              const Spacer(),
              Text(
                '৳${result.totalFare.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppConstants.primaryGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrafficInfo(JourneyPlannerState state, bool isDark) {
    final traffic = state.trafficInfo;
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;

    Color statusColor;
    switch (traffic.level) {
      case TrafficLevel.low:
        statusColor = AppConstants.successGreen;
        break;
      case TrafficLevel.moderate:
        statusColor = AppConstants.fareAmber;
        break;
      default:
        statusColor = AppConstants.errorRed;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : AppConstants.cardLine),
      ),
      child: Row(
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.4), blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'বর্তমান ট্রাফিক',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: AppConstants.fontBengali,
                  color: isDark ? Colors.white54 : AppConstants.inkSoft,
                ),
              ),
              Text(
                traffic.labelBn,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppConstants.fontBengali,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            'গাড়ির গতি: ~${(20 * traffic.multiplier).toStringAsFixed(0)} কিমি/ঘ',
            style: TextStyle(
              fontSize: 11,
              fontFamily: AppConstants.fontBengali,
              color: isDark ? Colors.white54 : AppConstants.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}
