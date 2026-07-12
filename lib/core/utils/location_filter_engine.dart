import 'dart:math';
import '../../models/gps_point.dart';
import '../constants/app_constants.dart';

class LocationFilterResult {
  final bool accepted;
  final double distanceDelta;
  final String? statusMessage;
  final GpsPoint? filteredPoint;

  LocationFilterResult({
    required this.accepted,
    this.distanceDelta = 0,
    this.statusMessage,
    this.filteredPoint,
  });
}

class LocationFilterEngine {
  GpsPoint? _lastValidPoint;
  bool _isPaused = false;
  double _lastDistanceDelta = 0;

  double _smoothedLat = 0;
  double _smoothedLng = 0;
  double _smoothedSpeed = 0;
  double _smoothedHeading = 0;
  bool _hasSmoothed = false;

  LocationFilterEngine();

  GpsPoint _applySmoothing(GpsPoint point) {
    if (!_hasSmoothed) {
      _smoothedLat = point.latitude;
      _smoothedLng = point.longitude;
      _smoothedSpeed = point.speed;
      _smoothedHeading = point.heading;
      _hasSmoothed = true;
      return point;
    }

    final alpha = AppConstants.gpsSmoothingAlpha;
    final speedAlpha = AppConstants.speedSmoothingAlpha;
    final headingAlpha = AppConstants.headingSmoothingAlpha;

    _smoothedLat = _smoothedLat + alpha * (point.latitude - _smoothedLat);
    _smoothedLng = _smoothedLng + alpha * (point.longitude - _smoothedLng);
    _smoothedSpeed = _smoothedSpeed + speedAlpha * (point.speed - _smoothedSpeed);
    _smoothedHeading = _smoothedHeading + headingAlpha * (point.heading - _smoothedHeading);

    if (_smoothedHeading < 0) _smoothedHeading += 360;
    if (_smoothedHeading >= 360) _smoothedHeading -= 360;

    return GpsPoint(
      latitude: _smoothedLat,
      longitude: _smoothedLng,
      accuracy: point.accuracy,
      speed: _smoothedSpeed,
      heading: _smoothedHeading,
      timestamp: point.timestamp,
    );
  }

  LocationFilterResult processPoint(GpsPoint point) {
    if (point.accuracy > AppConstants.gpsMaxAccuracy) {
      return LocationFilterResult(
        accepted: false,
        distanceDelta: 0,
        statusMessage: 'GPS সিগন্যাল দুর্বল',
      );
    }

    final smoothed = _applySmoothing(point);

    if (_lastValidPoint == null) {
      _lastValidPoint = smoothed;
      _isPaused = false;
      return LocationFilterResult(
        accepted: false,
        distanceDelta: 0,
        statusMessage: 'প্রথম পয়েন্ট সেট',
        filteredPoint: smoothed,
      );
    }

    final distanceDelta = _calculateDistance(
      _lastValidPoint!.latitude,
      _lastValidPoint!.longitude,
      smoothed.latitude,
      smoothed.longitude,
    );

    _lastDistanceDelta = distanceDelta;

    if (distanceDelta < AppConstants.minDistanceDelta) {
      return LocationFilterResult(
        accepted: false,
        distanceDelta: 0,
        statusMessage: 'অপেক্ষা করুন...',
      );
    }

    if (distanceDelta > AppConstants.maxDistanceDelta) {
      _lastValidPoint = smoothed;
      return LocationFilterResult(
        accepted: false,
        distanceDelta: 0,
        statusMessage: 'GPS জাম্প',
      );
    }

    if (smoothed.speed < AppConstants.speedPauseThreshold) {
      _isPaused = true;
      _lastValidPoint = smoothed;
      return LocationFilterResult(
        accepted: true,
        distanceDelta: 0,
        statusMessage: 'জ্যামে দাঁড়িয়ে',
        filteredPoint: smoothed,
      );
    }

    _isPaused = false;
    final addedDistance = distanceDelta / 1000;
    _lastValidPoint = smoothed;

    final moving = smoothed.speed >= AppConstants.speedMovingThreshold;

    return LocationFilterResult(
      accepted: true,
      distanceDelta: addedDistance,
      statusMessage: moving ? null : 'ধীর গতি',
      filteredPoint: smoothed,
    );
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371000;

    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final deltaPhi = (lat2 - lat1) * pi / 180;
    final deltaLambda = (lon2 - lon1) * pi / 180;

    final a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  bool get isPaused => _isPaused;

  double get lastDistanceDelta => _lastDistanceDelta;

  void reset() {
    _lastValidPoint = null;
    _isPaused = false;
    _lastDistanceDelta = 0;
    _hasSmoothed = false;
    _smoothedLat = 0;
    _smoothedLng = 0;
    _smoothedSpeed = 0;
    _smoothedHeading = 0;
  }
}
