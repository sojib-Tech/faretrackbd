import '../core/utils/fare_calculator.dart';
import '../data/dhaka_bus_route_data.dart';
import '../data/stop_coordinates.dart';

class CorridorBusRoute {
  final String nameEn;
  final String nameBn;
  final List<String> stops;
  final String? type;
  final String? time;

  const CorridorBusRoute({
    required this.nameEn,
    required this.nameBn,
    required this.stops,
    this.type,
    this.time,
  });
}

String _corridorNormalize(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\u0980-\u09FF]'), '');

bool _stopMatchesPlace(String stopName, String queryPlace) {
  final a = _corridorNormalize(stopName);
  final b = _corridorNormalize(queryPlace);
  if (a.isEmpty || b.isEmpty) return false;
  return a.contains(b) || b.contains(a);
}

String _resolveToEnglish(String placeName) {
  final sc = StopCoordinates.find(placeName);
  if (sc != null) return sc.name;
  return placeName;
}

List<CorridorBusRoute> _allCorridorBuses = [];

Future<List<CorridorBusRoute>> loadCorridorBuses() async {
  if (_allCorridorBuses.isNotEmpty) return _allCorridorBuses;
  final buses = await DhakaBusRouteData.load();
  _allCorridorBuses = buses.map((b) => CorridorBusRoute(
    nameEn: b.nameEn,
    nameBn: b.nameBn,
    stops: b.route,
    type: b.type,
    time: b.time,
  )).toList();
  return _allCorridorBuses;
}

List<CorridorBusRoute> findCorridorBuses(
  List<CorridorBusRoute> allBuses,
  String originPlace,
  String destinationPlace,
) {
  final originEn = _resolveToEnglish(originPlace);
  final destEn = _resolveToEnglish(destinationPlace);

  final matches = <CorridorBusRoute>[];
  for (final bus in allBuses) {
    final originIdx = bus.stops.indexWhere(
      (s) => _stopMatchesPlace(s, originEn),
    );
    if (originIdx == -1) continue;

    final destIdx = bus.stops.indexWhere(
      (s) => _stopMatchesPlace(s, destEn),
    );
    if (destIdx == -1) continue;
    if (destIdx == originIdx) continue;

    matches.add(bus);
  }
  return matches;
}

double corridorDistanceKm(CorridorBusRoute bus, String originPlace, String destinationPlace) {
  final originEn = _resolveToEnglish(originPlace);
  final destEn = _resolveToEnglish(destinationPlace);

  final originIdx = bus.stops.indexWhere(
    (s) => _stopMatchesPlace(s, originEn),
  );
  final destIdx = bus.stops.indexWhere(
    (s) => _stopMatchesPlace(s, destEn),
  );
  if (originIdx == -1 || destIdx == -1) return 0;
  final low = originIdx < destIdx ? originIdx : destIdx;
  final high = originIdx < destIdx ? destIdx : originIdx;
  return (high - low).toDouble() * 0.5;
}

double corridorFare(CorridorBusRoute bus, String originPlace, String destinationPlace) {
  final km = corridorDistanceKm(bus, originPlace, destinationPlace);
  if (km <= 0) return 0;
  return calculateDhakaBusFare(km).toDouble();
}

bool corridorIsAc(CorridorBusRoute bus) {
  final type = bus.type?.toLowerCase() ?? '';
  return type.contains('ac');
}

Future<List<CorridorBusMatch>> findAllCorridorBuses(
  String originPlace,
  String destinationPlace,
) async {
  final allBuses = await loadCorridorBuses();
  final originEn = _resolveToEnglish(originPlace);
  final destEn = _resolveToEnglish(destinationPlace);
  final matches = findCorridorBuses(allBuses, originPlace, destinationPlace);

  return matches.map((bus) {
    final km = corridorDistanceKm(bus, originPlace, destinationPlace);
    final fare = corridorFare(bus, originPlace, destinationPlace);
    final originIdx = bus.stops.indexWhere(
      (s) => _stopMatchesPlace(s, originEn),
    );
    final destIdx = bus.stops.indexWhere(
      (s) => _stopMatchesPlace(s, destEn),
    );
    final low = originIdx < destIdx ? originIdx : destIdx;
    final high = originIdx < destIdx ? destIdx : originIdx;
    return CorridorBusMatch(
      bus: bus,
      distanceKm: km,
      fare: fare,
      isAc: corridorIsAc(bus),
      stopsBetween: high - low - 1,
      originStopName: bus.stops[low],
      destStopName: bus.stops[high],
    );
  }).toList()..sort((a, b) => a.fare.compareTo(b.fare));
}

class CorridorBusMatch {
  final CorridorBusRoute bus;
  final double distanceKm;
  final double fare;
  final bool isAc;
  final int stopsBetween;
  final String originStopName;
  final String destStopName;

  const CorridorBusMatch({
    required this.bus,
    required this.distanceKm,
    required this.fare,
    required this.isAc,
    this.stopsBetween = 0,
    this.originStopName = '',
    this.destStopName = '',
  });
}
