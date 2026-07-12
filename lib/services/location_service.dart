import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/gps_point.dart';

class LocationService {
  static final LocationService _instance = LocationService._();
  factory LocationService() => _instance;
  LocationService._();

  StreamSubscription<Position>? _positionSubscription;
  StreamController<GpsPoint>? _controller;
  int _listenerCount = 0;

  Future<bool> requestPermissions() async {
    final location = await Permission.location.request();
    if (location.isGranted) {
      await Permission.locationAlways.request();
      return true;
    }
    return false;
  }

  Future<bool> hasPermissions() async {
    final location = await Permission.location.status;
    return location.isGranted;
  }

  Future<bool> hasBackgroundPermission() async {
    final status = await Permission.locationAlways.status;
    return status.isGranted;
  }

  Stream<GpsPoint> startListening({
    LocationAccuracy accuracy = LocationAccuracy.best,
    int distanceFilter = 2,
  }) {
    _listenerCount++;

    if (_controller != null) {
      return _controller!.stream;
    }

    _controller = StreamController<GpsPoint>.broadcast();

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    ).listen((position) {
      _controller!.add(GpsPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
        heading: position.heading,
        timestamp: position.timestamp,
      ));
    });

    return _controller!.stream;
  }

  void stopListening() {
    _listenerCount--;
    if (_listenerCount <= 0) {
      _listenerCount = 0;
      _positionSubscription?.cancel();
      _positionSubscription = null;
      _controller?.close();
      _controller = null;
    }
  }

  bool get isListening => _controller != null;

  Stream<GpsPoint> get currentStream {
    if (_controller == null) {
      return const Stream.empty();
    }
    return _controller!.stream;
  }

  Future<GpsPoint?> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return GpsPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
        heading: position.heading,
        timestamp: position.timestamp,
      );
    } catch (e) {
      return null;
    }
  }
}
