import '../data/bus_database.dart';

class RouteSuggestion {
  final BusInfo bus;
  final int startIndex;
  final int endIndex;
  final int stopGap;
  final bool isDirect;
  final String? connectingBus;
  final String? midStop;

  int get stopCount => endIndex - startIndex;

  List<String> get travelStops =>
      bus.stops.sublist(startIndex, endIndex + 1);

  RouteSuggestion({
    required this.bus,
    required this.startIndex,
    required this.endIndex,
    required this.stopGap,
    this.isDirect = true,
    this.connectingBus,
    this.midStop,
  });
}

class RouteFinderService {
  static const List<String> _hubStops = [
    'Kuril Bishwa Road', 'Farmgate', 'Shahbag', 'Gabtoli', 'Mohakhali',
    'Gulistan', 'Motijheel', 'Mirpur 10', 'Airport', 'Notun Bazar',
    'Badda', 'Rampura Bridge', 'Technical', 'Shyamoli', 'Khilkhet',
    'Banani', 'Paltan', 'GPO', 'High Court', 'Kallyanpur',
  ];

  static List<RouteSuggestion> findRoutes(String start, String end) {
    final s = start.trim();
    final e = end.trim();
    if (s.isEmpty || e.isEmpty || s == e) return [];

    final direct = _findDirectBuses(s, e);
    if (direct.isNotEmpty) return direct;

    return _findConnectingBuses(s, e);
  }

  static List<RouteSuggestion> _findDirectBuses(String start, String end) {
    final results = <RouteSuggestion>[];

    for (final bus in BusDatabase.allBuses) {
      final stops = bus.stops;
      int si = -1, ei = -1;

      for (var i = 0; i < stops.length; i++) {
        if (_match(stops[i], start)) si = i;
        if (_match(stops[i], end)) ei = i;
      }

      if (si >= 0 && ei >= 0 && si < ei) {
        results.add(RouteSuggestion(
          bus: bus,
          startIndex: si,
          endIndex: ei,
          stopGap: ei - si,
        ));
      }
    }

    results.sort((a, b) {
      final gapCmp = a.stopGap.compareTo(b.stopGap);
      if (gapCmp != 0) return gapCmp;
      return a.bus.name.compareTo(b.bus.name);
    });

    return results.take(5).toList();
  }

  static List<RouteSuggestion> _findConnectingBuses(String start, String end) {
    final results = <double, RouteSuggestion>{};

    for (final hub in _hubStops) {
      final toHub = _findDirectBuses(start, hub);
      final fromHub = _findDirectBuses(hub, end);

      if (toHub.isEmpty || fromHub.isEmpty) continue;

      for (final first in toHub.take(2)) {
        for (final second in fromHub.take(2)) {
          final totalStops = first.stopGap + second.stopGap;
          final score = totalStops + (first.bus == second.bus ? 0.0 : 5.0);
          if (!results.containsKey(score)) {
            results[score] = RouteSuggestion(
              bus: first.bus,
              startIndex: first.startIndex,
              endIndex: first.endIndex,
              stopGap: first.stopGap,
              isDirect: false,
              connectingBus: second.bus.name,
              midStop: hub,
            );
          }
        }
      }
    }

    final sorted = results.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return sorted.take(3).map((e) => e.value).toList();
  }

  static bool _match(String stop, String query) {
    final q = query.toLowerCase().trim();
    final s = stop.toLowerCase().trim();

    if (s == q || s.contains(q) || q.contains(s)) return true;

    const aliases = {
      'uttara': 'jashimuddin',
      'kuril': 'kuril bishwa road',
      'jamuna': 'jamuna future park',
      'bashundhara': 'bashundhara',
      'badda': 'badda',
      'merul': 'merul',
      'rampura': 'rampura bridge',
      'malibagh': 'malibagh moor',
      'shantinagar': 'shantinagar',
      'kakrail': 'kakrail',
      'mouchak': 'mouchak',
      'mogbazar': 'mogbazar',
      'nabisco': 'nabisco',
      'chairman': 'chairman bari',
      'sainik': 'sainik club',
      'kakali': 'kakali',
      'shewra': 'shewrapara',
      'kalshi': 'kalshi',
      'purobi': 'purobi',
      'pallabi': 'pallabi',
      'mirpur 10': 'mirpur 10',
      'mirpur 2': 'mirpur 2',
      'mirpur 1': 'mirpur 1',
      'mirpur 12': 'mirpur 12',
      'gabtoli': 'gabtoli',
      'technical': 'technical',
      'shyamoli': 'shyamoli',
      'agargaon': 'agargaon',
      'bijoy': 'bijoy sarani',
      'jahangir': 'jahangir gate',
      'mohakhali': 'mohakhali',
      'gulshan 1': 'gulshan 1',
      'banani': 'banani',
      'khilkhet': 'khilkhet',
      'airport': 'airport',
      'abdullahpur': 'abdullahpur',
      'tongi': 'tongi',
      'gazipur': 'gazipur chourasta',
    };

    if (aliases.containsKey(q)) {
      return s.contains(aliases[q]!);
    }

    return false;
  }
}
