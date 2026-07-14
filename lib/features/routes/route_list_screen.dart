import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/bus_route_provider.dart';
import '../../models/bus_route.dart';
import 'route_detail_screen.dart';
import 'intercity_detail_screen.dart';

class RouteListScreen extends ConsumerStatefulWidget {
  const RouteListScreen({super.key});

  @override
  ConsumerState<RouteListScreen> createState() => _RouteListScreenState();
}

class _RouteListScreenState extends ConsumerState<RouteListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final routesAsync = ref.watch(filteredRoutesProvider);
    final searchQuery = ref.watch(routeSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('বাস রুট সমূহ'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'রুট বা স্টপেজ খুঁজুন...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(routeSearchProvider.notifier).state = '';
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) {
                ref.read(routeSearchProvider.notifier).state = v;
              },
            ),
          ),
          Expanded(
            child: routesAsync.when(
              data: (routes) => routes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text('কোনো রুট পাওয়া যায়নি',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[500])),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: routes.length,
                      itemBuilder: (_, i) => _RouteCard(route: routes[i]),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteCard extends ConsumerWidget {
  final RouteItem route;
  const _RouteCard({required this.route});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          FocusScope.of(context).unfocus();
          if (route is BusRoute) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RouteDetailScreen(route: route as BusRoute),
              ),
            );
          } else if (route is DdrRoute) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => IntercityDetailScreen(route: route as DdrRoute),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (isDark ? AppConstants.primaryAccent : AppConstants.primaryGreen)
                      .withValues(alpha: route.isIntercity ? 0.08 : 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    route.routeNo,
                    style: TextStyle(
                      fontSize: route.isIntercity ? 10 : 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppConstants.primaryAccent : AppConstants.primaryGreen,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.straight_rounded, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${route.totalDistanceKm} কিমি',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                        if (route is BusRoute) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.alt_route_rounded, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            '${(route as BusRoute).stopCount} স্টপেজ',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                        if (route.isIntercity) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.airline_seat_flat_rounded, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            '৫১/৮০ আসন',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
