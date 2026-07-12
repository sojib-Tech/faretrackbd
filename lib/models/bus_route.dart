/// Base class for all route items (metro and intercity).
abstract class RouteItem {
  String get id;
  String get nameBn;
  String get nameEn;
  String get routeNo;
  double get totalDistanceKm;
  bool get isIntercity => false;

  const RouteItem();
}

class BusStop {
  final String name;
  final double distanceFromStartKm;

  const BusStop({required this.name, required this.distanceFromStartKm});
}

class BusRoute extends RouteItem {
  @override
  final String id;
  @override
  final String nameBn;
  @override
  final String nameEn;
  @override
  final String routeNo;
  @override
  final double totalDistanceKm;
  final List<BusStop> stops;
  final List<List<double>> fareData;

  const BusRoute({
    required this.id,
    required this.nameBn,
    required this.nameEn,
    required this.routeNo,
    required this.totalDistanceKm,
    required this.stops,
    required this.fareData,
  });

  int get stopCount => stops.length;

  BusStop get firstStop => stops.first;
  BusStop get lastStop => stops.last;

  /// Get fare between two stops using the source-table format.
  /// fareData[i] has i values: [fare to stop 0, fare to stop 1, ..., fare to stop i-1]
  double? getFare(int fromIndex, int toIndex) {
    if (fromIndex < 0 || fromIndex >= stopCount) return null;
    if (toIndex < 0 || toIndex >= stopCount) return null;
    if (fromIndex == toIndex) return 0;
    final row = fromIndex > toIndex ? fromIndex : toIndex;
    final col = fromIndex < toIndex ? fromIndex : toIndex;
    if (row >= fareData.length || col >= fareData[row].length) return null;
    return fareData[row][col];
  }

  double? getDistanceBetween(int fromIndex, int toIndex) {
    if (fromIndex < 0 || fromIndex >= stopCount) return null;
    if (toIndex < 0 || toIndex >= stopCount) return null;
    return (stops[toIndex].distanceFromStartKm -
            stops[fromIndex].distanceFromStartKm)
        .abs();
  }
}

class DdrRoute extends RouteItem {
  final int serial;
  @override
  final String id;
  final String previousRouteNo;
  @override
  final String nameBn;
  @override
  final String nameEn;
  @override
  final String routeNo;
  @override
  final double totalDistanceKm;
  final double farePerKm;
  final double fare51SeatWithoutToll;
  final double fare80SeatWithoutToll;
  final double toll;
  final double tollPerPassenger51Seat;
  final double tollPerPassenger80Seat;
  final double totalFare51Seat;
  final double totalFare80Seat;

  @override
  bool get isIntercity => true;

  const DdrRoute({
    required this.serial,
    required this.id,
    required this.previousRouteNo,
    required this.nameBn,
    required this.nameEn,
    required this.routeNo,
    required this.totalDistanceKm,
    required this.farePerKm,
    required this.fare51SeatWithoutToll,
    required this.fare80SeatWithoutToll,
    required this.toll,
    required this.tollPerPassenger51Seat,
    required this.tollPerPassenger80Seat,
    required this.totalFare51Seat,
    required this.totalFare80Seat,
  });
}
