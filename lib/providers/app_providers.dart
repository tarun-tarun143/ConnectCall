
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/call_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/call_service.dart';
import '../services/network_service.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import '../services/zego_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final messagingProvider = Provider<FirebaseMessaging>(
  (ref) => FirebaseMessaging.instance,
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(
    auth: ref.read(firebaseAuthProvider),
    firestore: ref.read(firestoreProvider),
  ),
);

final userServiceProvider = Provider<UserService>(
  (ref) => UserService(
    firestore: ref.read(firestoreProvider),
  ),
);

final callServiceProvider = Provider<CallService>(
  (ref) => CallService(
    ref.read(firestoreProvider),
  ),
);

final networkServiceProvider = Provider<NetworkService>(
  (ref) => NetworkService(),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(
    ref.read(firestoreProvider),
    ref.read(messagingProvider),
  ),
);

final zegoServiceProvider = Provider<ZegoService>(
  (ref) => ZegoService(
    callService: ref.read(callServiceProvider),
  ),
);

final authUserProvider = StreamProvider<User?>(
  (ref) => ref.read(authServiceProvider).authStateChanges,
);

final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  final uid = ref.watch(authUserProvider).value?.uid;

  if (uid == null || uid.isEmpty) {
    return const Stream<UserModel?>.empty();
  }

  return ref.read(userServiceProvider).watchUser(uid);
});

final usersProvider = StreamProvider<List<UserModel>>((ref) {
  final uid = ref.watch(authUserProvider).value?.uid;

  if (uid == null || uid.isEmpty) {
    return const Stream<List<UserModel>>.empty();
  }

  return ref.read(userServiceProvider).watchUsers(uid);
});

final historyProvider = StreamProvider<List<CallModel>>((ref) {
  final uid = ref.watch(authUserProvider).value?.uid;

  if (uid == null || uid.isEmpty) {
    return const Stream<List<CallModel>>.empty();
  }

  return ref.read(callServiceProvider).history(uid);
});

final themeModeProvider =
    NotifierProvider<ThemeController, ThemeMode>(
  ThemeController.new,
);

class ThemeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void setMode(ThemeMode value) => state = value;

  void toggle() {
    state = switch (state) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.system => ThemeMode.dark,
    };
  }
}

String createCallId(String caller, String callee) {
  final stamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  final left = _shortCallPart(caller);
  final right = _shortCallPart(callee);

  return 'cc_${left}_${right}_$stamp';
}

String _shortCallPart(String value) {
  final cleaned = value
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');

  if (cleaned.isEmpty) return 'user';

  return cleaned.length <= 10 ? cleaned : cleaned.substring(0, 10);
}
