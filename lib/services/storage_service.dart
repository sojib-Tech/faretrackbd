import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip_model.dart';
import '../models/user_model.dart';

class StorageService {
  static const _themeKey = 'theme_mode';
  static const _onboardingKey = 'onboarding_complete';
  static const _tripsKeyPrefix = 'trips_';
  static const _activeTripKey = 'active_trip';
  static const _guestId = 'guest';
  static const _guestSessionKey = 'guest_session_active';

  String _tripsKeyFor(String? userId) => '$_tripsKeyPrefix${userId ?? _guestId}';
  static const _usersKey = 'user_';
  static const _currentUserIdKey = 'current_user_id';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool getIsDarkMode() {
    return _prefs?.getBool(_themeKey) ?? false;
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
    if (json == null) return [];
    final List<dynamic> decoded = jsonDecode(json);
    return decoded
        .map((e) => TripModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveTrips(List<TripModel> trips, {String? userId}) async {
    final key = _tripsKeyFor(userId);
    final json = jsonEncode(trips.map((t) => t.toJson()).toList());
    await _prefs?.setString(key, json);
  }

  Future<void> addTrip(TripModel trip, {String? userId}) async {
    final trips = await getTrips(userId: userId);
    trips.insert(0, trip);
    await saveTrips(trips, userId: userId);
  }

  Future<void> deleteTrip(String tripId, {String? userId}) async {
    final trips = await getTrips(userId: userId);
    trips.removeWhere((t) => t.id == tripId);
    await saveTrips(trips, userId: userId);
  }

  Future<void> deleteAllTrips({String? userId}) async {
    await saveTrips([], userId: userId);
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
