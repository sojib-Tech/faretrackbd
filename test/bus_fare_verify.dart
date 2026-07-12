import 'package:faretrackbd/models/bus_route.dart';
import 'package:faretrackbd/data/bus_route_data.dart';

int errors = 0;
int checks = 0;

void main() {
  for (final route in BusRouteData.allRoutes) {
    // Row-per-stop format: fareData has stops rows, row i has i values
    if (route.fareData.length != route.stops.length) {
      print(
          'ERROR: ${route.id} has ${route.fareData.length} fareData rows, expected ${route.stops.length}');
      errors++;
    }

    for (int i = 0; i < route.fareData.length; i++) {
      if (route.fareData[i].length != i) {
        print(
            'ERROR: ${route.id} fareData[$i] has ${route.fareData[i].length} values, expected $i');
        errors++;
      }
    }

    // Symmetry check: fare(i,j) == fare(j,i) for all pairs
    final n = route.stops.length;
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        if (i == j) continue;
        checks++;
        final fwd = route.getFare(i, j);
        final rev = route.getFare(j, i);
        if (fwd != rev) {
          print(
              'SYMMETRY ERROR: ${route.id} fare($i,$j)=$fwd != fare($j,$i)=$rev');
          errors++;
        }
      }
    }

    // Spot checks
    if (route.id == 'A-285') {
      check(route, 0, 11, 53);
      check(route, 1, 3, 10);
      check(route, 0, 1, 10);
      check(route, 5, 6, 10);
      check(route, 4, 6, 14);
    }
    if (route.id == 'A-288') {
      check(route, 0, 12, 89);
      check(route, 0, 1, 10);
      check(route, 6, 7, 10);
    }
    if (route.id == 'A-292') {
      check(route, 0, 11, 101);
      check(route, 4, 5, 10);
    }
    if (route.id == 'A-304') {
      check(route, 0, 16, 81);
      check(route, 5, 6, 10);
    }
    if (route.id == 'A-327') {
      check(route, 0, 6, 34);
      check(route, 1, 2, 18);
      check(route, 2, 6, 18);
    }
    if (route.id == 'A-309') {
      check(route, 0, 9, 106);
      check(route, 1, 2, 10);
      check(route, 2, 3, 10);
      check(route, 5, 6, 20);
    }
    if (route.id == 'A-330') {
      check(route, 0, 15, 80);
    }
    if (route.id == 'A-310') {
      check(route, 0, 12, 50);
      check(route, 6, 7, 12);
    }
    if (route.id == 'A-319') {
      check(route, 0, 10, 78);
    }
    if (route.id == 'A-331') {
      check(route, 0, 19, 148);
    }
    if (route.id == 'A-341') {
      check(route, 0, 18, 123);
    }
  }

  if (errors == 0) {
    print(
        'ALL PASSED! $checks symmetry checks, ${BusRouteData.allRoutes.length} routes verified, 0 errors.');
  } else {
    print('$errors ERRORS in $checks checks!');
  }
}

void check(BusRoute route, int from, int to, double expected) {
  checks++;
  final fare = route.getFare(from, to);
  if (fare != expected) {
    print(
        'SPOT CHECK ERROR: ${route.id} ${route.stops[from].name}->${route.stops[to].name}: got $fare, expected $expected');
    errors++;
  }
}
