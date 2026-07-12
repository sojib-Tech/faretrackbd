import '../models/bus_route.dart';
import '../data/bus_route_data.dart';
import '../data/ddr_route_data.dart';

class SearchResultItem {
  final RouteItem route;
  final String matchedField;
  final String subtitle;

  const SearchResultItem({
    required this.route,
    required this.matchedField,
    required this.subtitle,
  });
}

class BusSearchService {
  static List<RouteItem> get _allRoutes => [
        ...BusRouteData.allRoutes,
        ...DdrRouteData.allRoutes,
      ];

  static List<SearchResultItem> search(String query) {
    if (query.trim().isEmpty) return [];
    final q = query.trim().toLowerCase();
    final results = <SearchResultItem>[];
    final seen = <String>{};

    for (final route in _allRoutes) {
      if (seen.contains(route.id)) continue;

      if (route.routeNo.toLowerCase() == q) {
        results.add(SearchResultItem(
          route: route,
          matchedField: 'রুট নং ${route.routeNo}',
          subtitle: route.nameBn,
        ));
        seen.add(route.id);
        continue;
      }

      if (route.routeNo.toLowerCase().contains(q)) {
        results.add(SearchResultItem(
          route: route,
          matchedField: 'রুট নং ${route.routeNo}',
          subtitle: route.nameBn,
        ));
        seen.add(route.id);
        continue;
      }

      final nameBnLower = route.nameBn.toLowerCase();
      if (nameBnLower == q) {
        results.add(SearchResultItem(
          route: route,
          matchedField: route.nameBn,
          subtitle: 'রুট নং ${route.routeNo}',
        ));
        seen.add(route.id);
        continue;
      }

      if (nameBnLower.contains(q)) {
        results.add(SearchResultItem(
          route: route,
          matchedField: route.nameBn,
          subtitle: 'রুট নং ${route.routeNo}',
        ));
        seen.add(route.id);
        continue;
      }

      if (route is BusRoute) {
        for (final stop in route.stops) {
          final stopLower = stop.name.toLowerCase();
          if (stopLower == q || stopLower.contains(q)) {
            results.add(SearchResultItem(
              route: route,
              matchedField: 'স্টপ: ${stop.name}',
              subtitle: '${route.nameBn} (${route.routeNo})',
            ));
            seen.add(route.id);
            break;
          }
        }
      }
    }

    results.sort((a, b) {
      final aExact = a.matchedField.toLowerCase().contains(q) ? 0 : 1;
      final bExact = b.matchedField.toLowerCase().contains(q) ? 0 : 1;
      if (aExact != bExact) return aExact.compareTo(bExact);
      return a.route.nameBn.compareTo(b.route.nameBn);
    });

    return results;
  }
}
