import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Centralized Firebase Auth service for login, register, logout.
class AuthService {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;

  AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _usersRef =
      FirebaseDatabase.instance.ref().child('users');

  /// Stream of auth state changes (null = signed out)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current user or null if signed out
  User? get currentUser => _auth.currentUser;

  /// Current user ID or null
  String? get currentUserId => _auth.currentUser?.uid;

  /// Current user email
  String? get currentUserEmail => _auth.currentUser?.email;

  /// Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  /// Register with email and password. Optionally store displayName and phone.
  Future<User?> registerWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
    String? phone,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user;
    if (user != null) {
      try {
        if (displayName != null && displayName.isNotEmpty) {
          await user.updateDisplayName(displayName);
        }
      } catch (_) {
        // Ignore displayName update failure - user is still registered
      }
      try {
        await _saveUserProfile(
          uid: user.uid,
          email: user.email ?? email,
          displayName: displayName ?? user.displayName,
          phone: phone,
        );
      } catch (_) {
        // Ignore profile save failure - user is registered in Auth, profile can be updated later
      }
    }
    return user;
  }

  /// Sign in with email and password
  Future<User?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  /// Sign in with Google (works on web, iOS, and Android)
  Future<User?> signInWithGoogle() async {
    if (kIsWeb) {
      final cred = await _auth.signInWithPopup(GoogleAuthProvider());
      final user = cred.user;
      if (user != null) {
        try {
          await _saveUserProfile(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName,
            photoUrl: user.photoURL,
          );
        } catch (_) {}
      }
      return user;
    }
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final cred = await _auth.signInWithCredential(credential);
    final user = cred.user;
    if (user != null) {
      try {
        await _saveUserProfile(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? googleUser.displayName,
          photoUrl: user.photoURL ?? googleUser.photoUrl,
        );
      } catch (_) {}
    }
    return user;
  }

  /// Sign out
  Future<void> signOut() async {
    if (!kIsWeb) {
      await GoogleSignIn().signOut();
    }
    await _auth.signOut();
  }

  /// Save or update user profile in Realtime Database
  Future<void> _saveUserProfile({
    required String uid,
    required String email,
    String? displayName,
    String? phone,
    String? photoUrl,
  }) async {
    final data = <String, dynamic>{
      'email': email,
      'updatedAt': ServerValue.timestamp,
    };
    if (displayName != null && displayName.isNotEmpty) {
      data['displayName'] = displayName;
    }
    if (phone != null && phone.isNotEmpty) {
      data['phone'] = phone;
    }
    if (photoUrl != null && photoUrl.isNotEmpty) {
      data['photoUrl'] = photoUrl;
    }
    await _usersRef.child(uid).set(data);
  }

  /// Update user profile (displayName, phone, photoUrl)
  Future<void> updateProfile({
    String? displayName,
    String? phone,
    String? photoUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    if (displayName != null && displayName.isNotEmpty) {
      await user.updateDisplayName(displayName);
    }
    if (photoUrl != null && photoUrl.isNotEmpty) {
      try {
        await user.updatePhotoURL(photoUrl);
      } catch (_) {
        // Store in DB even if Auth photoURL fails
      }
    }
    final data = <String, dynamic>{
      'updatedAt': ServerValue.timestamp,
    };
    if (displayName != null && displayName.isNotEmpty) {
      data['displayName'] = displayName;
    }
    if (phone != null) {
      data['phone'] = phone;
    }
    if (photoUrl != null) {
      data['photoUrl'] = photoUrl;
    }
    await _usersRef.child(user.uid).update(data);
  }

  /// Get user profile from Realtime Database
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final snapshot = await _usersRef.child(uid).get();
    if (snapshot.value == null) return null;
    return Map<String, dynamic>.from(snapshot.value as Map);
  }

  /// Get current user's profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final uid = currentUserId;
    if (uid == null) return null;
    return getUserProfile(uid);
  }
}
