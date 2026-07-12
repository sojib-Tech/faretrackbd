class BusModel {
  final String busNameEn;
  final String busNameBn;
  final String banglaSearch;
  final String banglishSearch;
  final String englishSearch;

  BusModel({
    required this.busNameEn,
    required this.busNameBn,
    required this.banglaSearch,
    required this.banglishSearch,
    required this.englishSearch,
  });

  factory BusModel.fromJson(Map<String, dynamic> json) {
    return BusModel(
      busNameEn: json['bus_name_en'] ?? '',
      busNameBn: json['bus_name_bn'] ?? '',
      banglaSearch: json['bangla_search'] ?? '',
      banglishSearch: json['banglish_search'] ?? '',
      englishSearch: json['english_search'] ?? '',
    );
  }

  String get routePreview {
    final stops = banglaSearch.split(',');
    if (stops.length <= 3) return banglaSearch;
    return '${stops.first.trim()} → … → ${stops.last.trim()}';
  }
}
