
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/config/app_config.dart';
import '../core/utils/zego_ids.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  String zegoUserIdFor(String firebaseUid) =>
      ZegoIds.fromFirebaseUid(firebaseUid);

  String displayNameFor(User user) {
    final name = user.displayName?.trim() ?? '';
    if (name.isNotEmpty) return name;

    final emailName = user.email?.split('@').first.trim() ?? '';
    return emailName.isEmpty ? AppConfig.appName : emailName;
  }

  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
    String username = '',
    String phone = '',
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();
    final cleanUsername = username.trim().toLowerCase();
    final cleanPhone = phone.trim();

    final credential = await _auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw StateError('Account creation failed.');
    }

    await user.updateDisplayName(cleanName);
    await user.reload();

    final current = _auth.currentUser ?? user;

    await _firestore.collection('users').doc(current.uid).set({
      'name': cleanName,
      'username': cleanUsername,
      'email': cleanEmail,
      'phone': cleanPhone,
      'bio': '',
      'zegoId': zegoUserIdFor(current.uid),
      'online': true,
      'status': 'available',
      'avatarUrl': '',
      'photoUrl': '',
      'isVerified': current.emailVerified,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    try {
      await current.sendEmailVerification();
    } catch (_) {
      // Optional in local/demo Firebase environments.
    }

    return credential;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) =>
      login(email: email, password: password);

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      await ensureProfile(user);
      await setOnlineStatus(true);
    }

    return credential;
  }

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(
        email: email.trim().toLowerCase(),
      );

  Future<void> ensureProfile(User user) async {
    final ref = _firestore.collection('users').doc(user.uid);
    final snapshot = await ref.get();
    final data = snapshot.data() ?? const <String, dynamic>{};

    final oldName = (data['name'] as String?)?.trim();
    final username = (data['username'] as String?)?.trim() ?? '';
    final phone = (data['phone'] as String?)?.trim() ?? '';
    final bio = (data['bio'] as String?)?.trim() ?? '';
    final avatarUrl = (data['avatarUrl'] as String?)?.trim() ?? '';
    final photoUrl = (data['photoUrl'] as String?)?.trim() ?? '';

    await ref.set({
      'name': oldName == null || oldName.isEmpty
          ? displayNameFor(user)
          : oldName,
      'username': username,
      'email': user.email ?? '',
      'phone': phone,
      'bio': bio,
      'zegoId': zegoUserIdFor(user.uid),
      'online': true,
      'status': (data['status'] as String?) ?? 'available',
      'avatarUrl': avatarUrl.isNotEmpty ? avatarUrl : photoUrl,
      'photoUrl': photoUrl.isNotEmpty ? photoUrl : avatarUrl,
      'isVerified': user.emailVerified,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setOnlineStatus(bool online) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'online': online,
      'status': online ? 'available' : 'offline',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateProfile({
    required String name,
    String avatarUrl = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Not signed in.');

    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError('Name cannot be empty.');
    }

    await user.updateDisplayName(cleanName);

    await _firestore.collection('users').doc(user.uid).set({
      'name': cleanName,
      if (avatarUrl.trim().isNotEmpty) ...{
        'avatarUrl': avatarUrl.trim(),
        'photoUrl': avatarUrl.trim(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> logout() async {
    await setOnlineStatus(false);
    await _auth.signOut();
  }
}
