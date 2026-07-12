"""Generate correct fare data files from source table format.
Each route's fare data is stored as a list where fareData[i] = [fares to stops 0..i-1]
"""

from routes.route_data import ROUTES


def convert_to_row_format(route):
    """Convert triangular matrix to row-per-stop format"""
    stops = route["stops"]
    n = len(stops)
    old = route.get("fare_matrix", [])

    # Old format: fareMatrix[i][j] = fare from stop i to stop i+j+1
    # New format: fareData[i] = [fare to stop 0, fare to stop 1, ..., fare to stop i-1]
    
    fare_data = [[]]  # stop 0 has no previous stops
    
    for i in range(1, n):
        row = []
        for j in range(i):
            # fare from stop i to stop j
            # In old format: smaller=j, larger=i → fareMatrix[j][i-j-1]
            if j < len(old) and (i - j - 1) < len(old[j]):
                row.append(old[j][i - j - 1])
            else:
                print(f"WARNING: {route['id']}: missing fare({i},{j})")
                row.append(0)
        fare_data.append(row)
    
    return fare_data


def verify_fare_data(route, fare_data):
    """Verify fare data is consistent (symmetric)"""
    stops = route["stops"]
    n = len(stops)
    errors = []
    
    # Check structure
    for i in range(n):
        expected = i  # stop i should have i values
        actual = len(fare_data[i])
        if actual != expected:
            errors.append(f"  stop {i} ({stops[i]['name']}): {actual} values, expected {expected}")
    
    # Check fare(i,j) == fare(j,i) using the source fare_matrix
    fare_matrix = route.get("fare_matrix", [])
    for i in range(n):
        for j in range(i):
            # fare from i to j stored in fare_data[i][j]
            f_ij = fare_data[i][j] if j < len(fare_data[i]) else None
            # fare from j to i stored in fare_matrix[j][i-j-1]
            f_ji = fare_matrix[j][i-j-1] if j < len(fare_matrix) and (i-j-1) < len(fare_matrix[j]) else None
            
            if f_ij is not None and f_ji is not None and f_ij != f_ji:
                errors.append(f"  asymmetric: fare({i},{j})={f_ij} but fare({j},{i})={f_ji}")
    
    return errors


def generate_dart_code(routes_with_data):
    """Generate Dart code for the bus_route_data.dart file"""
    lines = []
    lines.append("// Auto-generated fare data - DO NOT EDIT MANUALLY")
    lines.append("// Source: Dhaka Metro Transport Committee bus fare chart")
    lines.append("")
    lines.append("import '../models/bus_route.dart';")
    lines.append("")
    lines.append("class BusRouteData {")
    lines.append("  static const List<BusRoute> allRoutes = [")
    
    for rd in routes_with_data:
        route = rd["route"]
        fare_data = rd["fare_data"]
        var_name = f"_route{rd['index']}"
        lines.append(f"    {var_name},")
    
    lines.append("  ];")
    lines.append("")
    lines.append("  static BusRoute? findById(String id) {")
    lines.append("    try {")
    lines.append("      return allRoutes.firstWhere((r) => r.id == id);")
    lines.append("    } catch (_) {")
    lines.append("      return null;")
    lines.append("    }")
    lines.append("  }")
    lines.append("")
    lines.append("  static List<BusRoute> search(String query) {")
    lines.append("    final q = query.toLowerCase();")
    lines.append("    return allRoutes.where((r) {")
    lines.append("      return r.nameBn.toLowerCase().contains(q) ||")
    lines.append("          r.nameEn.toLowerCase().contains(q) ||")
    lines.append("          r.routeNo.toLowerCase().contains(q) ||")
    lines.append("          r.stops.any((s) => s.name.toLowerCase().contains(q));")
    lines.append("    }).toList();")
    lines.append("  }")
    lines.append("}")
    lines.append("")
    
    for rd in routes_with_data:
        route = rd["route"]
        fare_data = rd["fare_data"]
        var_name = f"_route{rd['index']}"
        
        lines.append(f"// Route {rd['index']}: {route['name_bn']} [{route['id']}]")
        lines.append(f"const {var_name} = BusRoute(")
        lines.append(f"  id: '{route['id']}',")
        lines.append(f"  nameBn: '{route['name_bn']}',")
        lines.append(f"  nameEn: '{route['name_en']}',")
        lines.append(f"  routeNo: '{route['route_no']}',")
        lines.append(f"  totalDistanceKm: {route['total_distance_km']},")
        lines.append("  stops: [")
        for s in route["stops"]:
            lines.append(f"    BusStop(name: '{s['name']}', distanceFromStartKm: {s['distance_from_start_km']}),")
        lines.append("  ],")
        lines.append("  fareData: [")
        for i, row in enumerate(fare_data):
            if i == 0:
                lines.append("    <double>[],")
            else:
                vals = ", ".join(str(int(v)) if v == int(v) else str(v) for v in row)
                lines.append(f"    [{vals}],")
        lines.append("  ],")
        lines.append(");")
        lines.append("")
    
    return "\n".join(lines)


def main():
    routes_with_data = []
    all_errors = []
    
    for idx, route in enumerate(ROUTES, 1):
        n = len(route["stops"])
        fare_data = convert_to_row_format(route)
        routes_with_data.append({
            "index": idx,
            "route": route,
            "fare_data": fare_data,
        })
        
        errors = verify_fare_data(route, fare_data)
        if errors:
            all_errors.append(f"Route {route['id']} ({route['name_bn']}):")
            all_errors.extend(errors)
        
        # Print summary
        expected_total = n * (n - 1) // 2  # total fare values in triangular format
        actual_total = sum(len(row) for row in fare_data)
        print(f"  {route['id']}: {n} stops, {actual_total} fare entries "
              f"(expected {expected_total})")
    
    if all_errors:
        print("\nERRORS:")
        for e in all_errors:
            print(e)
    else:
        print(f"\nAll {len(routes_with_data)} routes verified OK!")
    
    # Generate Dart code
    dart_code = generate_dart_code(routes_with_data)
    with open("generated_bus_route_data.dart", "w", encoding="utf-8") as f:
        f.write(dart_code)
    print(f"\nGenerated {len(dart_code)} bytes of Dart code")


if __name__ == "__main__":
    main()
