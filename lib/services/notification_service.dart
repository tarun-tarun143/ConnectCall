import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  NotificationService(this._db, this._messaging);
  final FirebaseFirestore _db;
  final FirebaseMessaging _messaging;
  final StreamController<RemoteMessage> _foreground = StreamController.broadcast();
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;

  Stream<RemoteMessage> get foregroundMessages => _foreground.stream;

  Future<void> initialise(String uid) async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    final token = await _messaging.getToken();
    if (token != null) await _saveToken(uid, token);
    await _tokenSubscription?.cancel();
    _tokenSubscription = _messaging.onTokenRefresh.listen((value) => _saveToken(uid, value));
    await _messageSubscription?.cancel();
    _messageSubscription = FirebaseMessaging.onMessage.listen(_foreground.add);
  }

  Future<void> _saveToken(String uid, String token) {
    return _db.collection('users').doc(uid).set(
      {'fcmTokens': FieldValue.arrayUnion([token])},
      SetOptions(merge: true),
    );
  }

  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    await _messageSubscription?.cancel();
    await _foreground.close();
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // ZEGOCLOUD's signaling/call invitation service owns call UI delivery.
  // This handler exists so non-call FCM messages can be handled safely in the background.
}
