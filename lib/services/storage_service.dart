import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_model.dart';
import '../models/user_model.dart';

class StorageService {
  static const _themeKey = 'theme_mode';
  static const _onboardingKey = 'onboarding_complete';
  static const _tripsKeyPrefix = 'trips_';
  static const _activeTripKey = 'active_trip';
  static const _guestId = 'guest';
  static const _guestSessionKey = 'guest_session_active';

  String _tripsKeyFor(String? userId) =>
      '$_tripsKeyPrefix${userId ?? _guestId}';
  static const _usersKey = 'user_';
  static const _currentUserIdKey = 'current_user_id';

  SharedPreferences? _prefs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool getIsDarkMode() {
    return _prefs?.getBool(_themeKey) ?? true;
  }

  Future<void> setDarkMode(bool value) async {
    await _prefs?.setBool(_themeKey, value);
  }

  bool isOnboardingComplete() {
    return _prefs?.getBool(_onboardingKey) ?? false;
  }

  Future<void> setOnboardingComplete() async {
    await _prefs?.setBool(_onboardingKey, true);
  }

  Future<void> resetOnboarding() async {
    await _prefs?.setBool(_onboardingKey, false);
  }

  Future<List<TripModel>> getTrips({String? userId}) async {
    final key = _tripsKeyFor(userId);
    final json = _prefs?.getString(key);
    var localTrips = <TripModel>[];
    try {
      final decoded = json == null ? const [] : jsonDecode(json);
      if (decoded is List) {
        // Keep the profile boundary explicit even though the preference key is
        // already profile-specific. This protects against old or malformed data
        // being shown under another signed-in profile.
        localTrips = decoded
            .whereType<Map<String, dynamic>>()
            .map(TripModel.fromJson)
            .where((trip) => trip.userId == userId)
            .toList();
      }
    } catch (_) {
      localTrips = [];
    }

    if (userId == null) return localTrips;

    try {
      final remote = await _firestore
          .collection('trip_history')
          .where('userId', isEqualTo: userId)
          .get();
      final byId = <String, TripModel>{
        for (final trip in localTrips) trip.id: trip,
      };
      for (final doc in remote.docs) {
        byId[doc.id] = TripModel.fromJson(doc.data());
      }
      final mergedTrips = byId.values.toList()
        ..sort((a, b) => b.startTime.compareTo(a.startTime));
      await saveTrips(mergedTrips, userId: userId);
      return mergedTrips;
    } catch (_) {
      return localTrips;
    }
  }

  Future<void> saveTrips(List<TripModel> trips, {String? userId}) async {
    final key = _tripsKeyFor(userId);
    final json = jsonEncode(trips.map((t) => t.toJson()).toList());
    await _prefs?.setString(key, json);
  }

  Future<void> syncTripsToCloud({required String userId}) async {
    final json = _prefs?.getString(_tripsKeyFor(userId));
    if (json == null) return;
    try {
      final decoded = jsonDecode(json);
      if (decoded is! List) return;
      final trips = decoded
          .whereType<Map<String, dynamic>>()
          .map(TripModel.fromJson)
          .where((trip) => trip.userId == userId)
          .toList();
      for (var start = 0; start < trips.length; start += 400) {
        final batch = _firestore.batch();
        final end = (start + 400).clamp(0, trips.length).toInt();
        for (final trip in trips.sublist(start, end)) {
          batch.set(
            _firestore.collection('trip_history').doc(trip.id),
            trip.toJson(),
          );
        }
        await batch.commit();
      }
    } catch (_) {}
  }

  Future<void> addTrip(TripModel trip, {String? userId}) async {
    final trips = await getTrips(userId: userId);
    trips.insert(0, trip);
    await saveTrips(trips, userId: userId);
    if (userId != null) {
      // Keep the local copy, but let the caller know when cloud persistence
      // fails so the next authenticated sync can retry it.
      await _firestore
          .collection('trip_history')
          .doc(trip.id)
          .set(trip.toJson());
    }
  }

  Future<void> deleteTrip(String tripId, {String? userId}) async {
    final trips = await getTrips(userId: userId);
    trips.removeWhere((t) => t.id == tripId);
    await saveTrips(trips, userId: userId);
    if (userId != null) {
      try {
        await _firestore.collection('trip_history').doc(tripId).delete();
      } catch (_) {}
    }
  }

  Future<void> deleteAllTrips({String? userId}) async {
    await saveTrips([], userId: userId);
    if (userId != null) {
      try {
        final snapshot = await _firestore
            .collection('trip_history')
            .where('userId', isEqualTo: userId)
            .get();
        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      } catch (_) {}
    }
  }

  Future<void> saveActiveTrip(TripModel trip) async {
    final json = jsonEncode(trip.toJson());
    await _prefs?.setString(_activeTripKey, json);
  }

  Future<TripModel?> getActiveTrip() async {
    final json = _prefs?.getString(_activeTripKey);
    if (json == null) return null;
    return TripModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> clearActiveTrip() async {
    await _prefs?.remove(_activeTripKey);
  }

  // Auth methods — stores current Firebase user locally
  Future<UserModel?> getCurrentUser() async {
    final userId = _prefs?.getString(_currentUserIdKey);
    if (userId == null) return null;
    final json = _prefs?.getString('$_usersKey$userId');
    if (json == null) return null;
    return UserModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> setCurrentUser(UserModel user) async {
    await _prefs?.setString(_currentUserIdKey, user.id);
    await _prefs?.setString('$_usersKey${user.id}', jsonEncode(user.toJson()));
  }

  Future<void> clearCurrentUser() async {
    final userId = _prefs?.getString(_currentUserIdKey);
    if (userId != null) {
      await _prefs?.remove('$_usersKey$userId');
    }
    await _prefs?.remove(_currentUserIdKey);
  }

  bool isGuestSession() {
    return _prefs?.getBool(_guestSessionKey) ?? false;
  }

  Future<void> setGuestSession(bool value) async {
    await _prefs?.setBool(_guestSessionKey, value);
  }

  Future<void> clearGuestSession() async {
    await _prefs?.remove(_guestSessionKey);
  }
}
