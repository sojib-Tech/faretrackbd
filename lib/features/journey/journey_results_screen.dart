import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_constants.dart';
import '../../models/journey/journey_result.dart';
import '../../providers/journey_planner_provider.dart';
import 'journey_map_screen.dart';

class JourneyResultsScreen extends ConsumerStatefulWidget {
  const JourneyResultsScreen({super.key});

  @override
  ConsumerState<JourneyResultsScreen> createState() => _JourneyResultsScreenState();
}

class _JourneyResultsScreenState extends ConsumerState<JourneyResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabs = [
    ('সেরা', 'recommended'),
    ('দ্রুত', 'fastest'),
    ('সস্তা', 'cheapest'),
    ('কম হাঁটা', 'leastWalking'),
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
        title: const Text('বাসের পরামর্শ',
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
            state.error ?? 'কোনো বাস পাওয়া যায়নি',
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

  Widget _buildRouteList(List<JourneyResult> allResults, String pref, bool isDark) {
    List<JourneyResult> filtered;
    switch (pref) {
      case 'fastest':
        filtered = List.from(allResults)..sort((a, b) => a.totalTimeMinutes.compareTo(b.totalTimeMinutes));
        break;
      case 'cheapest':
        filtered = List.from(allResults)..sort((a, b) => a.totalFare.compareTo(b.totalFare));
        break;
      case 'leastWalking':
        filtered = List.from(allResults)..sort((a, b) =>
            a.totalWalkingDistanceMeters.compareTo(b.totalWalkingDistanceMeters));
        break;
      default:
        filtered = List.from(allResults)..sort((a, b) {
          if (a.isDirect && !b.isDirect) return -1;
          if (!a.isDirect && b.isDirect) return 1;
          return a.totalFare.compareTo(b.totalFare);
        });
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
      itemBuilder: (_, i) => _buildBusSuggestionCard(filtered[i], i, isDark, allResults),
    );
  }

  Widget _buildBusSuggestionCard(JourneyResult result, int index, bool isDark, List<JourneyResult> allResults) {
    final isRecommended = index == 0;
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final busSegs = result.busSegments;
    final firstBus = busSegs.isNotEmpty ? busSegs.first : null;

    final suggestions = _getWhySuggested(result, allResults);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        ref.read(journeyPlannerProvider.notifier).selectResult(result);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => JourneyMapScreen(result: result),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
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
              _buildHeader(result, isRecommended, isDark),
              const SizedBox(height: 10),
              _buildBusNameRow(firstBus, isDark),
              if (result.transferCount > 0) ...[
                const SizedBox(height: 6),
                _buildTransferInfo(result, isDark),
              ],
              const SizedBox(height: 10),
              _buildRouteWithArrows(result, isDark),
              const SizedBox(height: 12),
              _buildInfoGrid(result, isDark),
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildWhySuggested(suggestions, isDark),
              ],
              const SizedBox(height: 8),
              _buildBottomActions(result, isDark),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 300.ms, delay: Duration(milliseconds: index * 80)),
    );
  }

  Widget _buildHeader(JourneyResult result, bool isRecommended, bool isDark) {
    return Row(
      children: [
        if (isRecommended) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppConstants.primaryGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'সেরা পরামর্শ',
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
            result.isDirect ? 'সরাসরি বাস' : '${result.transferCount}টি ট্রান্সফার',
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppConstants.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '৳${result.totalFare.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: AppConstants.fontEnglish,
              color: AppConstants.primaryGreen,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusNameRow(BusSegment? seg, bool isDark) {
    if (seg == null) return const SizedBox.shrink();
    return Row(
      children: [
        Icon(
          seg.isAc ? Icons.ac_unit_rounded : Icons.directions_bus_rounded,
          size: 18,
          color: seg.isAc ? AppConstants.primaryAccent : AppConstants.primaryGreen,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${seg.busNameBn} (${seg.busNameEn})',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: AppConstants.fontBengali,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        if (seg.isAc)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: AppConstants.primaryAccent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'AC',
              style: TextStyle(
                fontSize: 9,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTransferInfo(JourneyResult result, bool isDark) {
    final transfers = result.transferSegments;
    final busSegs = result.busSegments;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppConstants.fareAmber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppConstants.fareAmber.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < busSegs.length; i++) ...[
            Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppConstants.fareAmber,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    busSegs[i].busNameBn,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppConstants.fontBengali,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Text(
                  '৳${busSegs[i].fare.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.fareAmber,
                  ),
                ),
              ],
            ),
            if (i < transfers.length) ...[
              Padding(
                padding: const EdgeInsets.only(left: 9),
                child: Row(
                  children: [
                    Container(width: 2, height: 16, color: AppConstants.fareAmber.withValues(alpha: 0.3)),
                    const SizedBox(width: 8),
                    Icon(Icons.swap_vert_rounded, size: 12, color: AppConstants.fareAmber),
                    const SizedBox(width: 4),
                    Text(
                      'ট্রান্সফার: ${transfers[i].fromStop}',
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: AppConstants.fontBengali,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildRouteWithArrows(JourneyResult result, bool isDark) {
    final stops = <String>[];
    for (final seg in result.busSegments) {
      if (stops.isEmpty) {
        stops.add(seg.boardStop);
      }
      stops.add(seg.alightStop);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'সম্পূর্ণ রুট',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: AppConstants.fontBengali,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: stops.asMap().entries.map((entry) {
              final i = entry.key;
              final stop = entry.value;
              final isFirst = i == 0;
              final isLast = i == stops.length - 1;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: isFirst
                          ? AppConstants.primaryGreen.withValues(alpha: 0.15)
                          : isLast
                              ? AppConstants.errorRed.withValues(alpha: 0.12)
                              : AppConstants.primaryAccent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      stop,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppConstants.fontBengali,
                        color: isFirst
                            ? AppConstants.primaryGreen
                            : isLast
                                ? AppConstants.errorRed
                                : AppConstants.primaryAccent,
                      ),
                    ),
                  ),
                  if (!isLast)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(Icons.arrow_forward_rounded, size: 10, color: Colors.grey),
                    ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(JourneyResult result, bool isDark) {
    final firstBus = result.busSegments.isNotEmpty ? result.busSegments.first : null;
    final boardingStop = firstBus?.boardStop ?? '';

    return Column(
      children: [
        Row(
          children: [
            _infoChip(Icons.payments_outlined, 'ভাড়া', '৳${result.totalFare.toStringAsFixed(0)}', AppConstants.fareAmber, isDark),
            const SizedBox(width: 8),
            _infoChip(Icons.straighten_rounded, 'দূরত্ব', result.totalDistanceFormatted, AppConstants.primaryGreen, isDark),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _infoChip(Icons.directions_bus_rounded, 'মোট স্টপ', '${result.busSegments.fold(0, (s, b) => s + b.stopCount)}', AppConstants.primaryAccent, isDark),
            const SizedBox(width: 8),
            _infoChip(Icons.access_time_rounded, 'সময়', result.totalTimeFormatted, AppConstants.primaryGreen, isDark),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (boardingStop.isNotEmpty)
              _infoChip(Icons.location_on_rounded, 'বোর্ডিং', boardingStop, AppConstants.primaryGreen, isDark),
            if (result.transferCount > 0) ...[
              const SizedBox(width: 8),
              _infoChip(Icons.swap_horiz_rounded, 'ট্রান্সফার', '${result.transferCount}বার', AppConstants.fareAmber, isDark),
            ],
          ],
        ),
      ],
    );
  }

  Widget _infoChip(IconData icon, String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontFamily: AppConstants.fontBengali,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: AppConstants.fontBengali,
                color: isDark ? Colors.white : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getWhySuggested(JourneyResult result, List<JourneyResult> allResults) {
    final suggestions = <String>[];

    if (result.isDirect) {
      suggestions.add('সরাসরি যাবে');
    }

    final minFare = allResults.map((r) => r.totalFare).reduce((a, b) => a < b ? a : b);
    if (result.totalFare == minFare) {
      suggestions.add('সবচেয়ে কম ভাড়া');
    }

    final minTime = allResults.map((r) => r.totalTimeMinutes).reduce((a, b) => a < b ? a : b);
    if (result.totalTimeMinutes == minTime) {
      suggestions.add('দ্রুততম সময়');
    }

    final minWalk = allResults.map((r) => r.totalWalkingDistanceMeters).reduce((a, b) => a < b ? a : b);
    if (result.totalWalkingDistanceMeters == minWalk && minWalk < 500) {
      suggestions.add('কাছের বাস');
    }

    final minDist = allResults.map((r) => r.totalDistanceKm).reduce((a, b) => a < b ? a : b);
    if (result.totalDistanceKm == minDist) {
      suggestions.add('কম দূরত্ব');
    }

    if (result.transferCount == 0 && allResults.any((r) => r.transferCount > 0)) {
      suggestions.add('কোনো ট্রান্সফার নেই');
    }

    return suggestions;
  }

  Widget _buildWhySuggested(List<String> suggestions, bool isDark) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: suggestions.map((s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppConstants.successGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppConstants.successGreen.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, size: 12, color: AppConstants.successGreen),
            const SizedBox(width: 4),
            Text(
              s,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                fontFamily: AppConstants.fontBengali,
                color: AppConstants.successGreen,
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildBottomActions(JourneyResult result, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              ref.read(journeyPlannerProvider.notifier).selectResult(result);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JourneyMapScreen(result: result),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppConstants.primaryGreen, AppConstants.pineDeep],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'মানচিত্রে দেখুন',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppConstants.fontBengali,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
