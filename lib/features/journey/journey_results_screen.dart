import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/journey/journey_plan.dart';
import '../../../models/journey/journey_result.dart';
import '../../../providers/journey_planner_provider.dart';
import 'journey_detail_screen.dart';

class JourneyResultsScreen extends ConsumerStatefulWidget {
  const JourneyResultsScreen({super.key});

  @override
  ConsumerState<JourneyResultsScreen> createState() => _JourneyResultsScreenState();
}

class _JourneyResultsScreenState extends ConsumerState<JourneyResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabs = [
    ('সেরা', RoutePreference.recommended),
    ('দ্রুত', RoutePreference.fastest),
    ('সস্তা', RoutePreference.cheapest),
    ('কম হাঁটা', RoutePreference.leastWalking),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(journeyPlannerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppConstants.backgroundDark : AppConstants.paper,
      appBar: AppBar(
        title: const Text('যাত্রা পরিকল্পনা',
            style: TextStyle(fontFamily: AppConstants.fontBengali)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppConstants.primaryGreen,
          unselectedLabelColor: AppConstants.inkSoft,
          indicatorColor: AppConstants.primaryGreen,
          labelStyle: const TextStyle(
            fontFamily: AppConstants.fontBengali,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: _tabs.map((t) => Tab(text: t.$1)).toList(),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.results.isEmpty
              ? _buildEmpty(state, isDark)
              : TabBarView(
                  controller: _tabController,
                  children: _tabs.map((tab) => _buildRouteList(
                    state.results,
                    tab.$2,
                    isDark,
                  )).toList(),
                ),
    );
  }

  Widget _buildEmpty(JourneyPlannerState state, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 72, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            state.error ?? 'কোনো রুট পাওয়া যায়নি',
            style: TextStyle(
              fontSize: 16,
              fontFamily: AppConstants.fontBengali,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteList(List<JourneyResult> allResults, RoutePreference pref, bool isDark) {
    List<JourneyResult> filtered;
    switch (pref) {
      case RoutePreference.fastest:
        filtered = List.from(allResults)..sort((a, b) => a.totalTimeMinutes.compareTo(b.totalTimeMinutes));
        break;
      case RoutePreference.cheapest:
        filtered = List.from(allResults)..sort((a, b) => a.totalFare.compareTo(b.totalFare));
        break;
      case RoutePreference.leastWalking:
        filtered = List.from(allResults)..sort((a, b) =>
            a.totalWalkingDistanceMeters.compareTo(b.totalWalkingDistanceMeters));
        break;
      default:
        filtered = allResults;
    }

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'এই ফিল্টারে কোনো রুট নেই',
          style: TextStyle(
            fontFamily: AppConstants.fontBengali,
            color: Colors.grey[500],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (_, i) => _buildOptionCard(filtered[i], i, isDark),
    );
  }

  Widget _buildOptionCard(JourneyResult result, int index, bool isDark) {
    final isRecommended = index == 0;
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        ref.read(journeyPlannerProvider.notifier).selectResult(result);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const JourneyDetailScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isRecommended
                ? AppConstants.primaryGreen
                : (isDark ? Colors.white12 : AppConstants.cardLine),
            width: isRecommended ? 2 : 1,
          ),
          boxShadow: isDark
              ? []
              : [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                )],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isRecommended) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'সেরা',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppConstants.fontBengali,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: result.isDirect
                          ? AppConstants.successGreen.withValues(alpha: 0.12)
                          : AppConstants.fareAmber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      result.isDirect ? 'সরাসরি' : '${result.transferCount}টি সংযোগ',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: AppConstants.fontBengali,
                        color: result.isDirect
                            ? AppConstants.successGreen
                            : AppConstants.fareAmber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'স্কোর: ${result.smartScore.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : AppConstants.inkSoft,
                      fontFamily: AppConstants.fontBengali,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildRoutePreview(result, isDark),
              const SizedBox(height: 10),
              _buildBusNames(result, isDark),
              const SizedBox(height: 10),
              _buildStatsRow(result, isDark),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 300.ms, delay: Duration(milliseconds: index * 100)),
    );
  }

  Widget _buildRoutePreview(JourneyResult result, bool isDark) {
    return Row(
      children: [
        _routeDot(AppConstants.fareAmber),
        ...result.busSegments.asMap().entries.expand((e) => [
          Expanded(
            child: Container(
              height: 2,
              color: e.value.isAc
                  ? AppConstants.primaryAccent.withValues(alpha: 0.5)
                  : AppConstants.primaryGreen.withValues(alpha: 0.5),
            ),
          ),
          if (e.key < result.busSegments.length - 1)
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(
                color: AppConstants.fareAmber,
                shape: BoxShape.circle,
              ),
            ),
        ]),
        _routeDot(AppConstants.primaryGreen),
      ],
    );
  }

  Widget _routeDot(Color color) {
    return Container(
      width: 10, height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildBusNames(JourneyResult result, bool isDark) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: result.busSegments.map((seg) {
        final isAc = seg.isAc;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isAc
                ? AppConstants.primaryAccent.withValues(alpha: 0.12)
                : AppConstants.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isAc
                  ? AppConstants.primaryAccent.withValues(alpha: 0.3)
                  : AppConstants.primaryGreen.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isAc ? Icons.ac_unit_rounded : Icons.directions_bus_rounded,
                size: 14,
                color: isAc ? AppConstants.primaryAccent : AppConstants.primaryGreen,
              ),
              const SizedBox(width: 5),
              Text(
                seg.busNameBn,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppConstants.fontBengali,
                  color: isAc ? AppConstants.primaryAccent : AppConstants.primaryGreen,
                ),
              ),
              if (isAc) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'AC',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatsRow(JourneyResult result, bool isDark) {
    return Row(
      children: [
        _stat(Icons.access_time_rounded, result.totalTimeFormatted, isDark),
        _stat(Icons.payments_outlined, '৳${result.totalFare.toStringAsFixed(0)}', isDark),
        _stat(Icons.directions_walk_rounded,
            '${result.totalWalkingDistanceMeters.toStringAsFixed(0)}মি', isDark),
        if (result.transferCount > 0)
          _stat(Icons.transfer_within_a_station_rounded,
              '${result.transferCount} সংযোগ', isDark),
        const Spacer(),
        Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
      ],
    );
  }

  Widget _stat(IconData icon, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: isDark ? Colors.white54 : AppConstants.inkSoft),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontFamily: AppConstants.fontBengali,
              color: isDark ? Colors.white70 : AppConstants.ink,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
