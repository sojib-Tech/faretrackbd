import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../data/bus_search_data.dart';
import '../models/bus_model.dart';

class BusSearchDelegate extends SearchDelegate<BusModel?> {
  BusSearchDelegate() : super(
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
  void showResults(BuildContext context) {
  }

  List<BusModel> _filterBuses(String query) {
    if (query.isEmpty) return [];
    final q = query.toLowerCase().trim();
    return allBuses.where((bus) {
      final matchesBangla = bus.banglaSearch.contains(q);
      final matchesBanglish = bus.banglishSearch.toLowerCase().contains(q);
      final matchesEnglish = bus.englishSearch.toLowerCase().contains(q);
      final matchesNameEn = bus.busNameEn.toLowerCase().contains(q);
      final matchesNameBn = bus.busNameBn.contains(q);
      return matchesBangla || matchesBanglish || matchesEnglish || matchesNameEn || matchesNameBn;
    }).toList();
  }

  Widget _buildResults(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final results = _filterBuses(query);

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
                child: Icon(Icons.search_rounded, size: 48, color: Colors.grey[400]),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                child: Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[400]),
              ),
              const SizedBox(height: 16),
              Text(
                '"$query" এর জন্য কিছু পাওয়া যায়নি',
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
        final bus = results[i];
        return _buildBusTile(context, bus, i, isDark);
      },
    );
  }

  Widget _buildBusTile(BuildContext context, BusModel bus, int index, bool isDark) {
    final stops = bus.banglaSearch.split(',').map((s) => s.trim()).toList();
    final previewStops = stops.length > 3
        ? '${stops.first} → … → ${stops.last}'
        : bus.banglaSearch;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        color: isDark ? Colors.grey[900] : Colors.grey[50],
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showBusRoute(context, bus, isDark),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryAccent.withValues(alpha: 0.12),
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
                        '${bus.busNameBn} (${bus.busNameEn})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.route_rounded, size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              previewStops,
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBusRoute(BuildContext context, BusModel bus, bool isDark) {
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
          final stops = bus.banglaSearch.split(',').map((s) => s.trim()).toList();
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
                Text(
                  bus.busNameBn,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppConstants.fontBengali,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bus.busNameEn,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                const SizedBox(height: 16),
                Text(
                  'স্টপেজ তালিকা (${stops.length}টি)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppConstants.fontBengali,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: stops.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final isStart = i == 0;
                      final isEnd = i == stops.length - 1;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
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
                            Text(
                              stops[i],
                              style: const TextStyle(
                                fontSize: 15,
                                fontFamily: AppConstants.fontBengali,
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
}
