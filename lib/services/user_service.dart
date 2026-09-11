import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class UserService {
  UserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<UserModel?> watchMe(String uid) => watchUser(uid);

  Stream<UserModel?> watchUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map(
          (doc) => doc.exists ? UserModel.fromDocument(doc) : null,
        );
  }

  Stream<List<UserModel>> watchUsers(String currentUid) {
    return _firestore
        .collection('users')
        .orderBy('name')
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(UserModel.fromDocument)
              .where((user) => user.id != currentUid)
              .toList(),
        );
  }

  Future<void> setPresence(
    String uid, {
    required bool online,
    String status = 'available',
  }) {
    return _firestore.collection('users').doc(uid).set(
      {
        'online': online,
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> values) {
    final data = <String, dynamic>{...values};
    final photoUrl = (data['photoUrl'] as String?)?.trim();
    final avatarUrl = (data['avatarUrl'] as String?)?.trim();
    if ((photoUrl ?? '').isNotEmpty && (avatarUrl ?? '').isEmpty) {
      data['avatarUrl'] = photoUrl;
    }
    data['updatedAt'] = FieldValue.serverTimestamp();
    return _firestore.collection('users').doc(uid).set(
          data,
          SetOptions(merge: true),
        );
  }

  Stream<bool> watchFavoriteForUser({
    required String currentUid,
    required String targetUid,
  }) {
    return _firestore
        .collection('users')
        .doc(currentUid)
        .collection('favorites')
        .doc(targetUid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Future<void> toggleFavoriteForUser({
    required String currentUid,
    required String targetUid,
    required bool favorite,
  }) {
    final ref = _firestore
        .collection('users')
        .doc(currentUid)
        .collection('favorites')
        .doc(targetUid);
    return favorite
        ? ref.set({'createdAt': FieldValue.serverTimestamp()})
        : ref.delete();
  }

  Future<void> blockUser({
    required String currentUid,
    required String targetUid,
  }) {
    return _firestore.collection('blockedUsers').doc('${currentUid}_$targetUid').set({
      'userId': currentUid,
      'blockedUserId': targetUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unblockUser({
    required String currentUid,
    required String targetUid,
  }) {
    return _firestore
        .collection('blockedUsers')
        .doc('${currentUid}_$targetUid')
        .delete();
  }
}
