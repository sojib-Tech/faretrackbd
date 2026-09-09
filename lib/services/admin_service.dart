import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip_model.dart';

class AdminProfile {
  final String id;
  final String name;
  final String email;
  final String authProvider;
  final bool banned;
  final DateTime? createdAt;

  const AdminProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.authProvider,
    required this.banned,
    this.createdAt,
  });

  factory AdminProfile.fromDocument(String id, Map<String, dynamic> data) {
    return AdminProfile(
      id: id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      authProvider: data['authProvider'] as String? ?? 'email',
      banned: data['banned'] == true,
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

  static const adminEmail = 'admin@faretrackbd.local';
  static final _firestore = FirebaseFirestore.instance;

  static bool isAdminEmail(String? email) =>
      email?.trim().toLowerCase() == adminEmail;

  static Future<void> login({
    required String username,
    required String password,
  }) async {
    if (username.trim().toLowerCase() != 'admin') {
      throw FirebaseAuthException(code: 'invalid-credential');
    }
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: adminEmail,
      password: password,
    );
    await _firestore.collection('users').doc(credential.user!.uid).set({
      'name': 'Administrator',
      'email': adminEmail,
      'role': 'admin',
      'authProvider': 'email',
      'createdAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  static Future<List<AdminProfile>> getProfiles() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs
        .where((doc) => !isAdminEmail(doc.data()['email'] as String?))
        .map((doc) => AdminProfile.fromDocument(doc.id, doc.data()))
        .toList();
  }

  static Future<bool> isCurrentUserAdmin() async {
    return isAdminEmail(FirebaseAuth.instance.currentUser?.email);
  }

  static Future<void> setBanned(String uid, bool banned) async {
    await _firestore.collection('users').doc(uid).update({'banned': banned});
  }

  static Future<void> deleteProfile(String uid) async {
    final history = await _firestore
        .collection('trip_history')
        .where('userId', isEqualTo: uid)
        .get();
    if (history.docs.isEmpty) {
      await _firestore.collection('users').doc(uid).delete();
      return;
    }
    for (var start = 0; start < history.docs.length; start += 400) {
      final batch = _firestore.batch();
      final end = (start + 400).clamp(0, history.docs.length).toInt();
      for (final doc in history.docs.sublist(start, end)) {
        batch.delete(doc.reference);
      }
      if (start == 0) {
        batch.delete(_firestore.collection('users').doc(uid));
      }
      await batch.commit();
    }
  }

  static Future<List<AdminHistoryRecord>> getAllHistory() async {
    final snapshot = await _firestore
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
