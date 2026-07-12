import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gps_point.dart';
import '../services/location_service.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/location_filter_engine.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>(
  (ref) {
    final service = ref.watch(locationServiceProvider);
    return LocationNotifier(service);
  },
);

class LocationState {
  final GpsPoint? currentPoint;
  final bool isListening;
  final double accuracy;
  final String statusMessage;
  final double speed;
  final bool isPaused;

  LocationState({
    this.currentPoint,
    this.isListening = false,
    this.accuracy = 0,
    this.statusMessage = '',
    this.speed = 0,
    this.isPaused = false,
  });

  LocationState copyWith({
    GpsPoint? currentPoint,
    bool? isListening,
    double? accuracy,
    String? statusMessage,
    double? speed,
    bool? isPaused,
  }) {
    return LocationState(
      currentPoint: currentPoint ?? this.currentPoint,
      isListening: isListening ?? this.isListening,
      accuracy: accuracy ?? this.accuracy,
      statusMessage: statusMessage ?? this.statusMessage,
      speed: speed ?? this.speed,
      isPaused: isPaused ?? this.isPaused,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  final LocationService _service;
  final LocationFilterEngine _filterEngine = LocationFilterEngine();
  StreamSubscription<GpsPoint>? _subscription;

  LocationNotifier(this._service) : super(LocationState());

  Future<bool> requestPermissions() async {
    return await _service.requestPermissions();
  }

  Stream<GpsPoint> locationStream() {
    return _service.currentStream;
  }

  void startListening() {
    if (state.isListening) return;

    final stream = _service.startListening(distanceFilter: 2);
    _subscription = stream.listen(_onPoint);
    state = state.copyWith(isListening: true);
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _service.stopListening();
    _filterEngine.reset();
    state = state.copyWith(
      isListening: false,
      statusMessage: '',
      isPaused: false,
    );
  }

  void _onPoint(GpsPoint point) {
    final result = _filterEngine.processPoint(point);

    String msg = result.statusMessage ?? '';
    if (msg.isEmpty && point.accuracy > AppConstants.gpsMaxAccuracy) {
      msg = 'GPS সিগন্যাল দুর্বল';
    } else if (msg.isEmpty && result.accepted) {
      msg = 'চলছে';
    }

    state = state.copyWith(
      currentPoint: result.filteredPoint ?? state.currentPoint,
      accuracy: point.accuracy,
      speed: point.speed,
      statusMessage: msg,
      isPaused: _filterEngine.isPaused,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
