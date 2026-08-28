import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/stop_coordinates.dart';
import '../../../core/utils/road_router.dart';
import '../../../models/journey/journey_plan.dart';
import '../../../models/journey/journey_result.dart';
import '../../../providers/journey_planner_provider.dart';
import '../../../widgets/glass_card.dart';
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
    ('সেরা', RoutePreference.recommended),
    ('দ্রুত', RoutePreference.fastest),
    ('সস্তা', RoutePreference.cheapest),
    ('কম হাঁটা', RoutePreference.leastWalking),
  ];

  final Map<String, List<LatLng>> _previewRoad = {};

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
      backgroundColor: Colors.transparent,
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
               : Column(
                children: [
                  _buildMapPreview(state.results.first, isDark),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: _tabs.map((tab) => _buildRouteList(
                        state.results,
                        tab.$2,
                        isDark,
                        state,
                      )).toList(),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildMapPreview(JourneyResult result, bool isDark) {
    final raw = _previewPoints(result);
    if (raw.length < 2) return const SizedBox.shrink();

    final pts = _previewRoad.containsKey(result.id)
        ? _previewRoad[result.id]!
        : raw;

    double lat = 0, lng = 0;
    for (final p in pts) {
      lat += p.latitude;
      lng += p.longitude;
    }
    final center = LatLng(lat / pts.length, lng / pts.length);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => JourneyMapScreen(result: result)),
      ),
      child: Container(
        height: 190,
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white12 : AppConstants.cardLine,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 12,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: AppConstants.tileUrl,
              userAgentPackageName: 'com.faretrackbd.app',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: pts,
                  color: Colors.white,
                  strokeWidth: 9,
                ),
                Polyline(
                  points: pts,
                  color: AppConstants.primaryGreen,
                  strokeWidth: 5,
                  pattern: const StrokePattern.solid(),
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: pts.first,
                  width: 30,
                  height: 30,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppConstants.primaryGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Center(
                      child: Text(
                        'A',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Marker(
                  point: pts.last,
                  width: 30,
                  height: 30,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppConstants.errorRed,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Center(
                      child: Text(
                        'B',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<LatLng> _previewPoints(JourneyResult result) {
    final pts = <LatLng>[];
    for (final seg in result.busSegments) {
      final route = seg.route;
      final start = seg.boardStopIndex < seg.alightStopIndex
          ? seg.boardStopIndex
          : seg.alightStopIndex;
      final end = seg.boardStopIndex < seg.alightStopIndex
          ? seg.alightStopIndex
          : seg.boardStopIndex;
      for (int i = start; i <= end && i < route.stops.length; i++) {
        final c = StopCoordinates.find(route.stops[i].name);
        if (c != null) pts.add(LatLng(c.lat, c.lng));
      }
    }
    return pts;
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

  Widget _buildRouteList(List<JourneyResult> allResults, RoutePreference pref, bool isDark, JourneyPlannerState state) {
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
        filtered = List.from(allResults)..sort((a, b) => b.smartScore.compareTo(a.smartScore));
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
      itemBuilder: (_, i) => _buildOptionCard(filtered[i], i, isDark, state, pref),
    );
  }

  Widget _buildOptionCard(JourneyResult result, int index, bool isDark, JourneyPlannerState state, RoutePreference pref) {
    final isRecommended = index == 0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        if (state.originLat != null &&
            state.originLng != null &&
            state.destLat != null &&
            state.destLng != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JourneyMapScreen(result: result),
            ),
          );
        }
      },
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 12),
        borderRadius: 18,
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
              _buildStatsRow(result, isDark, pref),
            ],
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

  Widget _buildStatsRow(JourneyResult result, bool isDark, RoutePreference pref) {
    final isFastest = pref == RoutePreference.fastest;
    final isCheapest = pref == RoutePreference.cheapest;
    final isLeastWalk = pref == RoutePreference.leastWalking;
    final bestGreen = AppConstants.primaryGreen;

    return Row(
      children: [
        _stat(
          Icons.access_time_rounded,
          result.totalTimeFormatted,
          isDark,
          highlight: isFastest,
          highlightColor: bestGreen,
        ),
        _stat(
          Icons.payments_outlined,
          '৳${result.totalFare.toStringAsFixed(0)}',
          isDark,
          highlight: isCheapest,
          highlightColor: bestGreen,
        ),
        _stat(
          Icons.directions_walk_rounded,
          '${result.totalWalkingDistanceMeters.toStringAsFixed(0)}মি',
          isDark,
          highlight: isLeastWalk,
          highlightColor: bestGreen,
        ),
        if (result.transferCount > 0)
          _stat(Icons.transfer_within_a_station_rounded,
              '${result.transferCount} সংযোগ', isDark),
        const Spacer(),
        Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
      ],
    );
  }

  Widget _stat(IconData icon, String text, bool isDark, {bool highlight = false, Color? highlightColor}) {
    final color = highlight && highlightColor != null ? highlightColor : null;
    return Container(
      padding: highlight ? const EdgeInsets.symmetric(horizontal: 6, vertical: 3) : null,
      decoration: highlight
          ? BoxDecoration(
              color: (highlightColor ?? AppConstants.primaryGreen).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Padding(
        padding: highlight ? EdgeInsets.zero : const EdgeInsets.only(right: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color ?? (isDark ? Colors.white54 : AppConstants.inkSoft)),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontFamily: AppConstants.fontBengali,
                color: color ?? (isDark ? Colors.white70 : AppConstants.ink),
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
