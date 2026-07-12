import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';
import '../firebase_options.dart';
import 'storage_provider.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return AuthNotifier(storage);
});

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isGuest;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isGuest = false,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? isGuest,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isGuest: isGuest ?? this.isGuest,
    );
  }

  bool get isAuthenticated => user != null;
  bool get isGuestMode => isGuest && !isAuthenticated;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final StorageService _storage;

  AuthNotifier(this._storage) : super(AuthState()) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    state = state.copyWith(isLoading: true);
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        final localUser = await _storage.getCurrentUser();
        if (localUser != null) {
          state = AuthState(user: localUser);
        } else if (_storage.isGuestSession()) {
          state = AuthState(isGuest: true);
        } else {
          state = AuthState();
        }
        return;
      }
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        state = AuthState(
          user: UserModel(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? data['email'] ?? '',
            name: data['name'] ?? '',
            photoURL: data['photoURL'] as String?,
            authProvider: data['authProvider'] as String? ?? 'email',
            createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
          ),
        );
        return;
      }
      final localUser = await _storage.getCurrentUser();
      if (localUser != null) {
        state = AuthState(user: localUser);
      } else {
        state = AuthState();
      }
    } catch (e) {
      debugPrint('Auth _loadUser error: $e');
      state = AuthState(error: 'Firebase লোড করতে ব্যর্থ: $e');
    }
  }

  Future<bool> _checkFirebaseInit() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      return true;
    } catch (e) {
      debugPrint('Firebase not initialized: $e');
      return false;
    }
  }

  Future<bool> signUp(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    if (name.trim().isEmpty || email.trim().isEmpty || password.isEmpty) {
      state = state.copyWith(isLoading: false, error: 'সব ফিল্ড পূরণ করুন');
      return false;
    }

    if (!_isValidEmail(email)) {
      state = state.copyWith(isLoading: false, error: 'সঠিক ইমেইল দিন');
      return false;
    }

    final pwdError = _isValidPassword(password);
    if (pwdError != null) {
      state = state.copyWith(isLoading: false, error: pwdError);
      return false;
    }

    if (!await _checkFirebaseInit()) {
      state = state.copyWith(isLoading: false, error: 'Firebase সংযোগ ব্যর্থ। Firebase কনসোল চেক করুন।');
      return false;
    }

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email.trim(), password: password);

      final user = UserModel(
        id: userCredential.user!.uid,
        email: email.trim(),
        name: name.trim(),
        authProvider: 'email',
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .set({
        'name': name.trim(),
        'email': email.trim(),
        'role': 'passenger',
        'authProvider': 'email',
        'createdAt': DateTime.now().toIso8601String(),
      });

      await _storage.setCurrentUser(user);
      state = AuthState(user: user);
      return true;
    } on FirebaseAuthException catch (e) {
      String msg;
      debugPrint('Auth signUp FirebaseAuthException: code=${e.code}, message=${e.message}');
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'এই ইমেইলে ইতিমধ্যে একটি অ্যাকাউন্ট আছে';
          break;
        case 'weak-password':
          msg = 'পাসওয়ার্ড খুবই দুর্বল';
          break;
        case 'invalid-email':
          msg = 'সঠিক ইমেইল দিন';
          break;
        case 'operation-not-allowed':
          msg = 'এই পদ্ধতিতে রেজিস্ট্রেশন বন্ধ আছে। Firebase কনসোল চেক করুন।';
          break;
        case 'network-request-failed':
          msg = 'নেটওয়ার্ক সমস্যা। আবার চেষ্টা করুন।';
          break;
        case 'api-key-not-valid':
          msg = 'Firebase API কী বৈধ নয়। Firebase কনসোল চেক করুন।';
          break;
        case 'invalid-api-key':
          msg = 'Firebase API কী বৈধ নয়। Firebase কনসোল চেক করুন।';
          break;
        default:
          msg = 'রেজিস্ট্রেশন ব্যর্থ হয়েছে ($e)';
      }
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    } catch (e) {
      debugPrint('Auth signUp error: $e');
      state = state.copyWith(isLoading: false, error: 'রেজিস্ট্রেশন ব্যর্থ হয়েছে। নেটওয়ার্ক ও Firebase কনফিগ চেক করুন।');
      return false;
    }
  }

  Future<bool> logIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    if (email.trim().isEmpty || password.isEmpty) {
      state = state.copyWith(isLoading: false, error: 'ইমেইল ও পাসওয়ার্ড দিন');
      return false;
    }

    if (!await _checkFirebaseInit()) {
      state = state.copyWith(isLoading: false, error: 'Firebase সংযোগ ব্যর্থ। Firebase কনসোল চেক করুন।');
      return false;
    }

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email.trim(), password: password);

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      UserModel user;
      if (doc.exists) {
        final data = doc.data()!;
        user = UserModel(
          id: userCredential.user!.uid,
          email: email.trim(),
          name: data['name'] ?? '',
          photoURL: data['photoURL'] as String?,
          authProvider: data['authProvider'] as String? ?? 'email',
          createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
        );
      } else {
        user = UserModel(
          id: userCredential.user!.uid,
          email: email.trim(),
          name: '',
          authProvider: 'email',
          createdAt: DateTime.now(),
        );
      }

      await _storage.setCurrentUser(user);
      state = AuthState(user: user);
      return true;
    } on FirebaseAuthException catch (e) {
      String msg;
      debugPrint('Auth logIn FirebaseAuthException: code=${e.code}, message=${e.message}');
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-credential':
          msg = 'ইমেইল বা পাসওয়ার্ড ভুল';
          break;
        case 'wrong-password':
          msg = 'ভুল পাসওয়ার্ড';
          break;
        case 'invalid-email':
          msg = 'সঠিক ইমেইল দিন';
          break;
        case 'too-many-requests':
          msg = 'অনেকবার চেষ্টা করেছেন, কিছুক্ষণ পর আবার চেষ্টা করুন';
          break;
        case 'operation-not-allowed':
          msg = 'এই পদ্ধতিতে লগইন বন্ধ আছে। Firebase কনসোল চেক করুন।';
          break;
        case 'network-request-failed':
          msg = 'নেটওয়ার্ক সমস্যা। আবার চেষ্টা করুন।';
          break;
        case 'api-key-not-valid':
        case 'invalid-api-key':
          msg = 'Firebase API কী বৈধ নয়। Firebase কনসোল চেক করুন।';
          break;
        default:
          msg = 'লগইন ব্যর্থ হয়েছে ($e)';
      }
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    } catch (e) {
      debugPrint('Auth login error: $e');
      state = state.copyWith(isLoading: false, error: 'লগইন ব্যর্থ হয়েছে। নেটওয়ার্ক ও Firebase কনফিগ চেক করুন।');
      return false;
    }
  }

  void setError(String msg) {
    state = state.copyWith(error: msg);
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    try {
      await FacebookAuth.i.logOut();
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    try {
      await _storage.clearCurrentUser();
    } catch (_) {}
    try {
      await _storage.clearGuestSession();
    } catch (_) {}
    state = AuthState();
  }

  Future<void> enterGuestMode() async {
    await _storage.setGuestSession(true);
    state = AuthState(isGuest: true);
  }

  Future<void> exitGuestMode() async {
    await _storage.clearGuestSession();
    state = AuthState();
  }

  Future<String?> resetPassword(String email) async {
    if (email.trim().isEmpty) return 'ইমেইল দিন';
    if (!_isValidEmail(email)) return 'সঠিক ইমেইল দিন';

    if (!await _checkFirebaseInit()) return 'Firebase সংযোগ ব্যর্থ';

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'এই ইমেইলে কোনো অ্যাকাউন্ট নেই';
        case 'invalid-email':
          return 'সঠিক ইমেইল দিন';
        case 'network-request-failed':
          return 'নেটওয়ার্ক সমস্যা। আবার চেষ্টা করুন।';
        default:
          return 'পাসওয়ার্ড রিসেট ইমেইল পাঠাতে ব্যর্থ ($e)';
      }
    } catch (e) {
      return 'পাসওয়ার্ড রিসেট ইমেইল পাঠাতে ব্যর্থ';
    }
  }

  static String? _isValidPassword(String password) {
    if (password.length < 8) return 'পাসওয়ার্ড কমপক্ষে ৮ অক্ষরের হতে হবে';
    if (!RegExp(r'[A-Z]').hasMatch(password)) return 'পাসওয়ার্ডে কমপক্ষে ১টি বড় হাতের অক্ষর থাকতে হবে';
    if (!RegExp(r'[a-z]').hasMatch(password)) return 'পাসওয়ার্ডে কমপক্ষে ১টি ছোট হাতের অক্ষর থাকতে হবে';
    if (!RegExp(r'[0-9]').hasMatch(password)) return 'পাসওয়ার্ডে কমপক্ষে ১টি সংখ্যা থাকতে হবে';
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return 'পাসওয়ার্ডে কমপক্ষে ১টি বিশেষ ক্যারেক্টার থাকতে হবে (!@#\$%^&* ইত্যাদি)';
    }
    return null;
  }

  static int getPasswordStrength(String password) {
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    if (password.length >= 16) score++;
    if (score <= 2) return 0;
    if (score <= 4) return 1;
    if (score <= 6) return 2;
    return 3;
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);

    if (!await _checkFirebaseInit()) {
      state = state.copyWith(isLoading: false, error: 'Firebase সংযোগ ব্যর্থ');
      return false;
    }

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        state = state.copyWith(isLoading: false, error: 'Google সাইন ইন বাতিল করা হয়েছে');
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseUser = userCredential.user!;

      return _handleSocialAuthUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? googleUser.email,
        name: firebaseUser.displayName ?? googleUser.displayName ?? '',
        photoURL: firebaseUser.photoURL ?? googleUser.photoUrl,
        authProvider: 'google',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth signInWithGoogle FirebaseAuthException: ${e.code}');
      String msg;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          msg = 'এই ইমেইলে অন্য একটি অ্যাকাউন্ট বিদ্যমান';
          break;
        case 'invalid-credential':
          msg = 'অবৈধ ক্রেডেনশিয়াল';
          break;
        case 'operation-not-allowed':
          msg = 'Google লগইন সক্রিয় নয়। Firebase কনসোল চেক করুন।';
          break;
        case 'network-request-failed':
          msg = 'নেটওয়ার্ক সমস্যা। আবার চেষ্টা করুন।';
          break;
        default:
          msg = 'Google সাইন ইন ব্যর্থ হয়েছে (${e.code})';
      }
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    } catch (e) {
      debugPrint('Auth signInWithGoogle error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Google সাইন ইন ব্যর্থ হয়েছে',
      );
      return false;
    }
  }

  Future<bool> signInWithFacebook() async {
    state = state.copyWith(isLoading: true, error: null);

    if (!await _checkFirebaseInit()) {
      state = state.copyWith(isLoading: false, error: 'Firebase সংযোগ ব্যর্থ');
      return false;
    }

    try {
      final LoginResult result = await FacebookAuth.i.login();

      if (result.status == LoginStatus.cancelled) {
        state = state.copyWith(isLoading: false, error: 'Facebook সাইন ইন বাতিল করা হয়েছে');
        return false;
      }

      if (result.status != LoginStatus.success || result.accessToken == null) {
        state = state.copyWith(isLoading: false, error: 'Facebook সাইন ইন ব্যর্থ হয়েছে');
        return false;
      }

      final OAuthCredential credential =
          FacebookAuthProvider.credential(result.accessToken!.tokenString);

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseUser = userCredential.user!;

      String name = firebaseUser.displayName ?? '';
      String? photoURL = firebaseUser.photoURL;

      if (name.isEmpty) {
        try {
          final graphResponse = await FacebookAuth.i.getUserData(
            fields: 'name,picture',
          );
          name = graphResponse['name'] ?? '';
          photoURL = graphResponse['picture']?['data']?['url'] ?? photoURL;
        } catch (_) {}
      }

      return _handleSocialAuthUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: name,
        photoURL: photoURL,
        authProvider: 'facebook',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth signInWithFacebook FirebaseAuthException: ${e.code}');
      String msg;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          msg = 'এই ইমেইলে অন্য একটি অ্যাকাউন্ট বিদ্যমান';
          break;
        case 'invalid-credential':
          msg = 'অবৈধ ক্রেডেনশিয়াল';
          break;
        case 'operation-not-allowed':
          msg = 'Facebook লগইন সক্রিয় নয়। Firebase কনসোল চেক করুন।';
          break;
        case 'network-request-failed':
          msg = 'নেটওয়ার্ক সমস্যা। আবার চেষ্টা করুন।';
          break;
        default:
          msg = 'Facebook সাইন ইন ব্যর্থ হয়েছে (${e.code})';
      }
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    } catch (e) {
      debugPrint('Auth signInWithFacebook error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Facebook সাইন ইন ব্যর্থ হয়েছে',
      );
      return false;
    }
  }

  Future<bool> _handleSocialAuthUser({
    required String uid,
    required String email,
    required String name,
    String? photoURL,
    required String authProvider,
  }) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final doc = await docRef.get();

      UserModel user;
      if (doc.exists) {
        final data = doc.data()!;
        user = UserModel(
          id: uid,
          email: email,
          name: data['name'] ?? name,
          photoURL: data['photoURL'] ?? photoURL,
          authProvider: data['authProvider'] ?? authProvider,
          createdAt:
              DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
        );
      } else {
        user = UserModel(
          id: uid,
          email: email,
          name: name,
          photoURL: photoURL,
          authProvider: authProvider,
          createdAt: DateTime.now(),
        );
        await docRef.set({
          'name': name,
          'email': email,
          'photoURL': photoURL,
          'role': 'passenger',
          'authProvider': authProvider,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }

      await _storage.setCurrentUser(user);
      state = AuthState(user: user);
      return true;
    } catch (e) {
      debugPrint('Auth _handleSocialAuthUser error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'অ্যাকাউন্ট তৈরি করতে ব্যর্থ হয়েছে',
      );
      return false;
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email.trim());
  }
}
