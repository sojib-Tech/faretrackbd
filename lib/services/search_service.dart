import '../data/bus_route_data.dart';
import '../data/stop_coordinates.dart';
import '../models/journey/stop_coordinate.dart';

class SearchSuggestion {
  final String displayName;
  final String displayNameBn;
  final String type;
  final StopCoordinate? coordinate;

  const SearchSuggestion({
    required this.displayName,
    required this.displayNameBn,
    required this.type,
    this.coordinate,
  });
}

class SearchService {
  static final Set<String> _allStopNames = {};
  static final Map<String, String> _banglaToEnglish = {};
  static bool _initialized = false;

  static void _ensureInit() {
    if (_initialized) return;
    _initialized = true;

    for (final route in BusRouteData.allRoutes) {
      for (final stop in route.stops) {
        final coord = StopCoordinates.find(stop.name);
        _allStopNames.add(stop.name);
        if (coord != null) {
          _banglaToEnglish[stop.name] = coord.name;
        }
      }
    }
  }

  static List<SearchSuggestion> search(String query) {
    _ensureInit();
    final q = query.trim();
    if (q.isEmpty) return [];

    final results = <SearchSuggestion>[];
    final seen = <String>{};

    for (final name in _allStopNames) {
      if (_fuzzyMatch(name, q)) {
        if (seen.add(name)) {
          final coord = StopCoordinates.find(name);
          final eng = _banglaToEnglish[name] ?? coord?.name ?? '';
          results.add(SearchSuggestion(
            displayName: eng,
            displayNameBn: name,
            type: 'bus_stop',
            coordinate: coord,
          ));
        }
      }
    }

    for (final coord in StopCoordinates.all) {
      if (_fuzzyMatch(coord.nameBn, q) || coord.name.toLowerCase().contains(q.toLowerCase())) {
        if (seen.add(coord.nameBn)) {
          results.add(SearchSuggestion(
            displayName: coord.name,
            displayNameBn: coord.nameBn,
            type: 'bus_stop',
            coordinate: coord,
          ));
        }
      }
    }

    results.sort((a, b) {
      final aExact = a.displayNameBn == q ? 0 : 1;
      final bExact = b.displayNameBn == q ? 0 : 1;
      if (aExact != bExact) return aExact - bExact;
      final aStarts = a.displayNameBn.startsWith(q) ? 0 : 1;
      final bStarts = b.displayNameBn.startsWith(q) ? 0 : 1;
      if (aStarts != bStarts) return aStarts - bStarts;
      return a.displayNameBn.compareTo(b.displayNameBn);
    });

    return results.take(15).toList();
  }

  static bool _fuzzyMatch(String target, String query) {
    final t = target.toLowerCase();
    final q = query.toLowerCase();

    if (t.contains(q) || q.contains(t)) return true;

    if (_levenshteinDistance(t, q) <= 2) return true;

    final tWords = t.split(RegExp(r'[\s,]+'));
    for (final word in tWords) {
      if (word.contains(q) || q.contains(word)) return true;
    }

    return false;
  }

  static int _levenshteinDistance(String s, String t) {
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    final matrix = List.generate(
      s.length + 1,
      (i) => List.generate(t.length + 1, (j) => 0),
    );

    for (var i = 0; i <= s.length; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= t.length; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i <= s.length; i++) {
      for (var j = 1; j <= t.length; j++) {
        final cost = s[i - 1] == t[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s.length][t.length];
  }
}
