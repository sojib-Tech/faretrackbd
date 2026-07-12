void main() {
  // Route data: (toll, table_pax_51, table_pax_80)
  final tolls = [
    (2520, 70.59, 90.00),
    (2495, 69.89, 89.11),
    (252, 7.06, 9.00),
    (295, 8.26, 10.54),
    (125, 3.50, 4.46),
    (100, 5.60, 7.14),
    (75, 2.10, 2.68),
    (60, 1.68, 2.14),
  ];

  print("Formula: pax_51 = toll / 35.7, pax_80 = toll / 28\n");

  for (final (t, t51, t80) in tolls) {
    final c51 = t / 35.7;
    final c80 = t / 28;
    final match51 = (c51 - t51).abs() < 0.015;
    final match80 = (c80 - t80).abs() < 0.015;
    print("toll=$t: table=[$t51, $t80] computed=[${c51.toStringAsFixed(2)}, ${c80.toStringAsFixed(2)}] "
        "${match51 && match80 ? '✅' : '❌'}");
    if (!match51) print("  mismatch 51: table=$t51 computed=${c51.toStringAsFixed(4)} diff=${(t51-c51).toStringAsFixed(4)}");
    if (!match80) print("  mismatch 80: table=$t80 computed=${c80.toStringAsFixed(4)} diff=${(t80-c80).toStringAsFixed(4)}");
  }
}
