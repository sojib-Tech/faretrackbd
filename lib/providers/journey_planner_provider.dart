import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/journey/journey_result.dart';
import '../services/journey_engine.dart';
import '../services/search_service.dart';
import '../services/nearest_stop_service.dart';
import '../services/eta_service.dart';

class JourneyPlannerState {
  final double? originLat;
  final double? originLng;
  final String originName;
  final double? destLat;
  final double? destLng;
  final String destName;
  final List<JourneyResult> results;
  final JourneyResult? selectedResult;
  final List<SearchSuggestion> searchResults;
  final List<NearbyStop> nearbyStops;
  final bool isLoading;
  final bool hasSearched;
  final String? error;
  final TrafficInfo trafficInfo;

  const JourneyPlannerState({
    this.originLat,
    this.originLng,
    this.originName = '',
    this.destLat,
    this.destLng,
    this.destName = '',
    this.results = const [],
    this.selectedResult,
    this.searchResults = const [],
    this.nearbyStops = const [],
    this.isLoading = false,
    this.hasSearched = false,
    this.error,
    this.trafficInfo = const TrafficInfo(
      level: TrafficLevel.moderate,
      multiplier: 1.2,
      labelBn: 'মাঝারি ট্রাফিক',
    ),
  });

  JourneyPlannerState copyWith({
    double? originLat,
    double? originLng,
    String? originName,
    double? destLat,
    double? destLng,
    String? destName,
    List<JourneyResult>? results,
    JourneyResult? selectedResult,
    bool clearSelectedResult = false,
    List<SearchSuggestion>? searchResults,
    List<NearbyStop>? nearbyStops,
    bool? isLoading,
    bool? hasSearched,
    String? error,
    bool clearError = false,
    bool clearDestCoords = false,
    TrafficInfo? trafficInfo,
  }) {
    return JourneyPlannerState(
      originLat: originLat ?? this.originLat,
      originLng: originLng ?? this.originLng,
      originName: originName ?? this.originName,
      destLat: clearDestCoords ? null : (destLat ?? this.destLat),
      destLng: clearDestCoords ? null : (destLng ?? this.destLng),
      destName: destName ?? this.destName,
      results: results ?? this.results,
      selectedResult: clearSelectedResult ? null : (selectedResult ?? this.selectedResult),
      searchResults: searchResults ?? this.searchResults,
      nearbyStops: nearbyStops ?? this.nearbyStops,
      isLoading: isLoading ?? this.isLoading,
      hasSearched: hasSearched ?? this.hasSearched,
      error: clearError ? null : (error ?? this.error),
      trafficInfo: trafficInfo ?? this.trafficInfo,
    );
  }
}

class JourneyPlannerNotifier extends StateNotifier<JourneyPlannerState> {
  JourneyPlannerNotifier() : super(JourneyPlannerState(trafficInfo: EtaService.getTrafficInfo()));

  void setOrigin(double lat, double lng, String name) {
    state = state.copyWith(originLat: lat, originLng: lng, originName: name);
    _loadNearbyStops(lat, lng);
  }

  void _loadNearbyStops(double lat, double lng) {
    final stops = NearestStopService.findNearby(
      latitude: lat,
      longitude: lng,
      radiusMeters: 1000,
    );
    state = state.copyWith(nearbyStops: stops);
  }

  void searchDestination(String query) {
    final results = SearchService.search(query);
    state = state.copyWith(searchResults: results);
  }

  void selectDestination(String name, {double? lat, double? lng}) {
    state = state.copyWith(
      destName: name,
      destLat: lat,
      destLng: lng,
      searchResults: [],
    );
  }

  void clearSearch() {
    state = state.copyWith(searchResults: [], clearError: true);
  }

  void selectResult(JourneyResult result) {
    state = state.copyWith(selectedResult: result);
  }

  void planJourney() {
    if (state.originLat == null || state.originLng == null || state.destName.isEmpty) {
      state = state.copyWith(error: 'শুরু ও গন্তব্য স্থান নির্বাচন করুন');
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSelectedResult: true,
    );

    final results = JourneyEngine.planFromText(
      originText: state.originName,
      destText: state.destName,
      userLat: state.originLat,
      userLng: state.originLng,
      destLat: state.destLat,
      destLng: state.destLng,
    );

    state = state.copyWith(
      isLoading: false,
      hasSearched: true,
      results: results,
      selectedResult: results.isNotEmpty ? results.first : null,
      error: results.isEmpty ? 'এই রুটে কোনো বাস পাওয়া যায়নি' : null,
    );
  }

  void refreshTraffic() {
    state = state.copyWith(trafficInfo: EtaService.getTrafficInfo());
  }
}

final journeyPlannerProvider =
    StateNotifierProvider<JourneyPlannerNotifier, JourneyPlannerState>((ref) {
  return JourneyPlannerNotifier();
});
