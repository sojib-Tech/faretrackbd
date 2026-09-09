import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip_model.dart';

class AdminProfile {
  final String id;
  final String name;
  final String email;
  final String authProvider;
  final DateTime? createdAt;

  const AdminProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.authProvider,
    this.createdAt,
  });

  factory AdminProfile.fromDocument(String id, Map<String, dynamic> data) {
    return AdminProfile(
      id: id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      authProvider: data['authProvider'] as String? ?? 'email',
      createdAt: DateTime.tryParse(data['createdAt'] as String? ?? ''),
    );
  }
}

class AdminHistoryRecord {
  final String userId;
  final TripModel trip;

  const AdminHistoryRecord({required this.userId, required this.trip});
}

class AdminService {
  AdminService._();

  static final _functions = FirebaseFunctions.instance;

  static Future<void> login({
    required String username,
    required String password,
  }) async {
    final result = await _functions.httpsCallable('adminLogin').call({
      'username': username.trim(),
      'password': password,
    });
    final token = result.data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw FirebaseFunctionsException(
        code: 'internal',
        message: 'Admin token was not returned.',
      );
    }
    await FirebaseAuth.instance.signInWithCustomToken(token);
  }

  static Future<List<AdminProfile>> getProfiles() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    return snapshot.docs
        .map((doc) => AdminProfile.fromDocument(doc.id, doc.data()))
        .toList();
  }

  static Future<bool> isCurrentUserAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final result = await user.getIdTokenResult(true);
    return result.claims?['admin'] == true;
  }

  static Future<void> deleteProfile(String uid) async {
    await _functions.httpsCallable('adminDeleteProfile').call({'uid': uid});
  }

  static Future<List<AdminHistoryRecord>> getAllHistory() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('trip_history')
        .orderBy('startTime', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return AdminHistoryRecord(
        userId: data['userId'] as String,
        trip: TripModel.fromJson(data),
      );
    }).toList();
  }

  static Future<void> logout() => FirebaseAuth.instance.signOut();
}
