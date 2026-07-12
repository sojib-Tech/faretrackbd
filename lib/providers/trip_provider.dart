import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/trip_model.dart';
import '../models/gps_point.dart';
import '../services/storage_service.dart';
import '../services/background_service.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/fare_calculator.dart';
import '../core/utils/location_filter_engine.dart';
import 'storage_provider.dart';
import 'auth_provider.dart';
import 'location_provider.dart';

final tripProvider = StateNotifierProvider<TripNotifier, TripState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final authState = ref.watch(authProvider);
  final locationNotifier = ref.watch(locationProvider.notifier);
  final userId = authState.user?.id;
  return TripNotifier(storage, locationNotifier, userId);
});

class TripState {
  final TripModel? currentTrip;
  final List<TripModel> trips;
  final bool isActive;
  final bool isLoading;
  final bool isJam;
  final double currentFare;
  final double currentDistance;
  final List<GpsPoint> routePoints;

  TripState({
    this.currentTrip,
    this.trips = const [],
    this.isActive = false,
    this.isLoading = false,
    this.isJam = false,
    this.currentFare = 0,
    this.currentDistance = 0,
    this.routePoints = const [],
  });

  TripState copyWith({
    TripModel? currentTrip,
    List<TripModel>? trips,
    bool? isActive,
    bool? isLoading,
    bool? isJam,
    double? currentFare,
    double? currentDistance,
    List<GpsPoint>? routePoints,
  }) {
    return TripState(
      currentTrip: currentTrip ?? this.currentTrip,
      trips: trips ?? this.trips,
      isActive: isActive ?? this.isActive,
      isLoading: isLoading ?? this.isLoading,
      isJam: isJam ?? this.isJam,
      currentFare: currentFare ?? this.currentFare,
      currentDistance: currentDistance ?? this.currentDistance,
      routePoints: routePoints ?? this.routePoints,
    );
  }
}

class TripNotifier extends StateNotifier<TripState> {
  final StorageService _storage;
  final String? _userId;
  final LocationNotifier _locationNotifier;
  final LocationFilterEngine _filterEngine = LocationFilterEngine();
  final BackgroundServiceManager _bgService = BackgroundServiceManager();
  StreamSubscription<GpsPoint>? _subscription;
  Timer? _jamTimer;
  Timer? _throttleTimer;
  int _jamSeconds = 0;
  int _gpsPointCount = 0;
  double _lastThrottledFare = 0;
  double _pendingDistance = 0;
  double _pendingFare = 0;
  bool _pendingJam = false;
  bool _disposed = false;
  List<GpsPoint> _pendingPoints = [];

  static const int _maxRoutePoints = 500;

  TripNotifier(this._storage, this._locationNotifier, this._userId)
      : super(TripState()) {
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    state = state.copyWith(isLoading: true);
    try {
      final trips = await _storage.getTrips(userId: _userId);
      state = state.copyWith(trips: trips, isLoading: false);
    } catch (e) {
      state = state.copyWith(trips: [], isLoading: false);
    }
  }

  Future<void> startTrip() async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final trip = TripModel(
      id: id,
      userId: _userId,
      startTime: now,
      status: TripStatus.active,
    );

    state = state.copyWith(
      currentTrip: trip,
      isActive: true,
      currentDistance: 0,
      currentFare: AppConstants.minimumFare,
      isJam: false,
      routePoints: [],
    );
    _lastThrottledFare = AppConstants.minimumFare;
    _pendingDistance = 0;
    _pendingFare = AppConstants.minimumFare;
    _pendingJam = false;
    _pendingPoints = [];

    try {
      await _storage.saveActiveTrip(trip);
    } catch (_) {}
    try {
      await _bgService.startService();
    } catch (_) {}
    try {
      _startLocationTracking();
    } catch (_) {}
  }

  void _startLocationTracking() {
    _filterEngine.reset();
    _jamSeconds = 0;
    _gpsPointCount = 0;

    _locationNotifier.startListening();
    try {
      final stream = _locationNotifier.locationStream();
      _subscription = stream.listen(
        (point) async => _onGpsPoint(point),
        onError: (e) {},
        cancelOnError: false,
      );
    } catch (e) {
      return;
    }

    _jamTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed) return;
      if (state.isJam) {
        _jamSeconds++;
      }
    });
  }

  Future<void> _onGpsPoint(GpsPoint point) async {
    if (_disposed) return;
    _gpsPointCount++;

    final result = _filterEngine.processPoint(point);

    if (!result.accepted && result.filteredPoint == null) return;

    final isFirstPoint = _gpsPointCount == 1;
    final distanceDelta = isFirstPoint ? 0.0 : result.distanceDelta;
    final newDistance = state.currentDistance + distanceDelta;
    final isJam = _filterEngine.isPaused;

    double jamDistanceDelta = 0;
    if (isJam && !isFirstPoint) {
      final rawDelta = _filterEngine.lastDistanceDelta;
      if (rawDelta > 0) {
        jamDistanceDelta = rawDelta / 1000;
      }
    }

    final fare = FareCalculator.calculateFare(newDistance);

    final newPoints = [...state.routePoints];
    if (result.filteredPoint != null) {
      newPoints.add(result.filteredPoint!);
    }
    if (newPoints.length > _maxRoutePoints) {
      newPoints.removeRange(0, newPoints.length - _maxRoutePoints);
    }

    _pendingDistance = newDistance;
    _pendingFare = fare;
    _pendingJam = isJam;
    _pendingPoints = newPoints;

    if (_throttleTimer == null || !_throttleTimer!.isActive) {
      _throttleTimer = Timer(const Duration(milliseconds: 400), () {
        if (_disposed) return;
        _flushPendingState();
      });
    }

    final fareDiff = (fare - _lastThrottledFare).abs();
    if (fareDiff >= 0.3 || _gpsPointCount % 3 == 0 || distanceDelta > 0.01) {
      if (_throttleTimer?.isActive == true && !_disposed) {
        _throttleTimer!.cancel();
      }
      _flushPendingState();
    }

    final trip = state.currentTrip;
    if (trip != null) {
      final updatedTrip = TripModel(
        id: trip.id,
        userId: trip.userId,
        startTime: trip.startTime,
        endTime: trip.endTime,
        totalDistanceKm: newDistance,
        totalFare: fare,
        jamDistanceKm: trip.jamDistanceKm + jamDistanceDelta,
        jamDuration: Duration(seconds: _jamSeconds),
        routePoints: newPoints,
        status: trip.status,
      );

      if (_gpsPointCount % 10 == 0) {
        try {
          await _storage.saveActiveTrip(updatedTrip);
        } catch (_) {}
      }
    }

    try {
      _bgService.updateLocation(
        distance: newDistance,
        fare: fare,
      );
    } catch (_) {}
  }

  void _flushPendingState() {
    _lastThrottledFare = _pendingFare;
    state = state.copyWith(
      currentDistance: _pendingDistance,
      currentFare: _pendingFare,
      isJam: _pendingJam,
      routePoints: List.from(_pendingPoints),
    );
  }

  Future<TripModel?> endTrip() async {
    state = state.copyWith(isLoading: true);

    // Flush any pending GPS state before finalizing
    _flushPendingState();

    _subscription?.cancel();
    _subscription = null;
    _jamTimer?.cancel();
    _jamTimer = null;
    _throttleTimer?.cancel();
    _throttleTimer = null;
    _filterEngine.reset();

    _locationNotifier.stopListening();

    try {
      await _bgService.stopService();
    } catch (_) {}

    final trip = state.currentTrip;
    if (trip != null) {
      trip.endTime = DateTime.now();
      trip.status = TripStatus.completed;
      trip.totalDistanceKm = state.currentDistance;
      trip.totalFare = state.currentFare;
      trip.jamDuration = Duration(seconds: _jamSeconds);

      try {
        await _storage.addTrip(trip, userId: _userId);
        await _storage.clearActiveTrip();
      } catch (_) {}
    }

    state = state.copyWith(
      currentTrip: null,
      isActive: false,
      isLoading: false,
      currentDistance: 0,
      currentFare: 0,
      isJam: false,
      routePoints: [],
    );

    return trip;
  }

  Future<void> deleteTrip(String tripId) async {
    try {
      await _storage.deleteTrip(tripId, userId: _userId);
    } catch (_) {}
    await _loadTrips();
  }

  Future<void> deleteAllTrips() async {
    try {
      await _storage.deleteAllTrips(userId: _userId);
    } catch (_) {}
    await _loadTrips();
  }

  Future<void> refreshTrips() async {
    await _loadTrips();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _subscription = null;
    _jamTimer?.cancel();
    _jamTimer = null;
    _throttleTimer?.cancel();
    _throttleTimer = null;
    _locationNotifier.stopListening();
    super.dispose();
  }
}
