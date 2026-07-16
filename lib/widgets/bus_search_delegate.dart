import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../data/bus_route_data.dart';
import '../models/bus_route.dart';
import '../models/journey/journey_result.dart';
import '../features/journey/journey_map_screen.dart';

class BusSearchDelegate extends SearchDelegate<BusRoute?> {
  BusSearchDelegate()
      : super(
          searchFieldLabel: 'বাস বা লোকেশন খুঁজুন...',
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.search,
        );

  @override
  ThemeData appBarTheme(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: Colors.grey[500],
          fontFamily: AppConstants.fontBengali,
        ),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_rounded),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildResults(context);

  @override
  void showResults(BuildContext context) {}

  List<BusRoute> _filterRoutes(String query) {
    if (query.isEmpty) return [];
    return BusRouteData.search(query);
  }

  Widget _buildResults(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final results = _filterRoutes(query);

    if (query.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(Icons.directions_bus_rounded,
                    size: 48, color: Colors.grey[400]),
              ),
              const SizedBox(height: 20),
              Text(
                'বাস বা লোকেশনের নাম লিখুন',
                style: TextStyle(
                  fontSize: 17,
                  fontFamily: AppConstants.fontBengali,
                  color: isDark ? Colors.grey[300] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'যেমন: মিরপুর, গুলশান, ফার্মগেট, মতিঝিল',
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: AppConstants.fontBengali,
                    color: Colors.grey[400],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'অথবা বাসের নাম: এ-২৮৫, চিড়িয়াখানা',
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: AppConstants.fontBengali,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(Icons.search_off_rounded,
                    size: 48, color: Colors.grey[400]),
              ),
              const SizedBox(height: 16),
              Text(
                '"$query" এর জন্য কিছু পাওয়া যায়নি',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: AppConstants.fontBengali,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: results.length,
      itemBuilder: (_, i) {
        final route = results[i];
        return _buildRouteTile(context, route, i, isDark);
      },
    );
  }

  Widget _buildRouteTile(
      BuildContext context, BusRoute route, int index, bool isDark) {
    final firstStop = route.stops.isNotEmpty ? route.stops.first.name : '';
    final lastStop = route.stops.isNotEmpty ? route.stops.last.name : '';
    final preview = route.stops.length > 2
        ? '$firstStop → … → $lastStop'
        : '$firstStop → $lastStop';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        color: isDark ? Colors.grey[900] : Colors.grey[50],
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showBusRoute(context, route, isDark),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryAccent
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppConstants.primaryAccent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.nameBn,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppConstants.fontBengali,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.route_rounded,
                              size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              preview,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[500]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        AppConstants.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${route.totalDistanceKm.toStringAsFixed(1)} কিমি',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBusRoute(BuildContext context, BusRoute route, bool isDark) {
    final stops = route.stops;
    final fare = route.getFare(0, stops.length - 1);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            route.nameBn,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: AppConstants.fontBengali,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${route.nameEn} · ${route.routeNo}',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryGreen
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${route.totalDistanceKm.toStringAsFixed(1)} কিমি',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _openRouteOnMap(context, route);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppConstants.primaryGreen,
                          AppConstants.pineDeep,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.map_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'মানচিত্রে দেখুন',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppConstants.fontBengali,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'স্টপেজ তালিকা (${stops.length}টি)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppConstants.fontBengali,
                        color:
                            isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                    if (fare != null) ...[
                      const Spacer(),
                      Text(
                        'ভাড়া: ৳${fare.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.fareAmber,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: stops.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final isStart = i == 0;
                      final isEnd = i == stops.length - 1;
                      final stopFare = route.getFare(0, i);
                      return Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isStart
                                        ? AppConstants.successGreen
                                        : isEnd
                                            ? AppConstants.warn
                                            : Colors.grey[400],
                                  ),
                                ),
                                if (i < stops.length - 1)
                                  Container(
                                    width: 2,
                                    height: 20,
                                    color: Colors.grey[300],
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                stops[i].name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontFamily:
                                      AppConstants.fontBengali,
                                ),
                              ),
                            ),
                            if (stopFare != null)
                              Text(
                                '৳${stopFare.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openRouteOnMap(BuildContext context, BusRoute route) {
    final segments = <JourneySegment>[];
    final stops = route.stops;

    if (stops.length >= 2) {
      final allSegments = <String>[];
      for (final stop in stops) {
        allSegments.add(stop.name);
      }

      segments.add(BusSegment(
        busNameEn: route.nameEn,
        busNameBn: route.nameBn,
        boardStop: stops.first.name,
        alightStop: stops.last.name,
        boardStopIndex: 0,
        alightStopIndex: stops.length - 1,
        fare: route.getFare(0, stops.length - 1) ?? 0,
        distanceKm: route.totalDistanceKm,
        travelTimeMinutes:
            (route.totalDistanceKm / 20 * 60).round().toDouble(),
        stopCount: stops.length - 1,
        trafficLevel: TrafficLevel.moderate,
        isAc: route.nameBn.contains('AC') ||
            route.nameEn.toLowerCase().contains('ac'),
        travelStops: allSegments,
        route: route,
      ));
    }

    if (segments.isEmpty) return;

    final result = JourneyResult(
      id: 'bus_route_${route.id}',
      originName: stops.first.name,
      destName: stops.last.name,
      segments: segments,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JourneyMapScreen(result: result),
      ),
    );
  }
}
