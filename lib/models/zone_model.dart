import 'dart:ui';

class DhakaZone {
  final int id;
  final String name;
  final String nameEn;
  final String color;
  final String type;
  final List<List<List<double>>> coordinates;

  const DhakaZone({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.color,
    required this.type,
    required this.coordinates,
  });

  factory DhakaZone.fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    final geometry = json['geometry'] as Map<String, dynamic>;
    final coords = geometry['coordinates'] as List;

    return DhakaZone(
      id: props['id'] as int,
      name: props['name'] as String,
      nameEn: props['nameEn'] as String,
      color: props['color'] as String,
      type: props['type'] as String,
      coordinates: (coords[0] as List)
          .map((ring) => (ring as List)
              .map((point) => (point as List).map((e) => (e as num).toDouble()).toList())
              .toList())
          .toList(),
    );
  }

  Color get fillColor => _parseColor(color);
  Color get borderColor => _parseColor(color).withValues(alpha: 0.8);

  Color _parseColor(String hex) {
    hex = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}
