
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/call_model.dart';

class CallHistoryService {
  CallHistoryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _calls =>
      _firestore.collection('calls');

  Stream<List<CallModel>> watchHistory(String uid) {
    return _calls
        .where(
          Filter.or(
            Filter('callerId', isEqualTo: uid),
            Filter('calleeId', isEqualTo: uid),
          ),
        )
        .limit(100)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => CallModel.fromDoc(doc, uid))
          .toList();

      items.sort((a, b) {
        final ad = a.createdAt;
        final bd = b.createdAt;

        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;

        return bd.compareTo(ad);
      });

      return items;
    });
  }

  Future<void> deleteHistoryItem(String callId) =>
      _calls.doc(callId).delete();

  Future<void> clearHistory(String uid) async {
    final snapshot = await _calls
        .where(
          Filter.or(
            Filter('callerId', isEqualTo: uid),
            Filter('calleeId', isEqualTo: uid),
          ),
        )
        .limit(100)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
