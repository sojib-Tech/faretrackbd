import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bus_route.dart';
import '../data/bus_route_data.dart';
import '../data/ddr_route_data.dart';

final allRoutesProvider = Provider<List<RouteItem>>((ref) {
  return [
    ...BusRouteData.allRoutes,
    ...DdrRouteData.allRoutes,
  ];
});

final routeSearchProvider = StateProvider<String>((ref) => '');

final filteredRoutesProvider = Provider<AsyncValue<List<RouteItem>>>((ref) {
  final query = ref.watch(routeSearchProvider);
  final routes = ref.watch(allRoutesProvider);
  if (query.isEmpty) return AsyncValue.data(routes);
  return AsyncValue.data(_search(routes, query));
});

final selectedRouteProvider = StateProvider<BusRoute?>((ref) => null);

List<RouteItem> _search(List<RouteItem> routes, String query) {
  final q = query.toLowerCase();
  return routes.where((r) {
    return r.nameBn.toLowerCase().contains(q) ||
        r.nameEn.toLowerCase().contains(q) ||
        r.routeNo.toLowerCase().contains(q) ||
        (r is BusRoute &&
            r.stops.any((s) => s.name.toLowerCase().contains(q)));
  }).toList();
}
