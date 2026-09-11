
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/call_model.dart';

class CallService {
  CallService(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _calls =>
      _db.collection('calls');

  Future<void> createOutgoing({
    required String callId,
    required String callerId,
    required String calleeId,
    required String callerName,
    required String calleeName,
    required CallType type,
  }) async {
    await _calls.doc(callId).set({
      'callId': callId,
      'callerId': callerId,
      'calleeId': calleeId,
      'callerName': callerName,
      'calleeName': calleeName,
      'type': type.name,
      'status': CallStatus.ringing.name,
      'createdAt': FieldValue.serverTimestamp(),
      'startedAt': null,
      'endedAt': null,
      'durationSeconds': 0,
    }, SetOptions(merge: true));
  }

  Future<void> registerIncoming({
    required String callId,
    required String callerId,
    required String calleeId,
    required String callerName,
    required String calleeName,
    required CallType type,
  }) async {
    final ref = _calls.doc(callId);

    if ((await ref.get()).exists) return;

    await ref.set({
      'callId': callId,
      'callerId': callerId,
      'calleeId': calleeId,
      'callerName': callerName,
      'calleeName': calleeName,
      'type': type.name,
      'status': CallStatus.ringing.name,
      'createdAt': FieldValue.serverTimestamp(),
      'startedAt': null,
      'endedAt': null,
      'durationSeconds': 0,
    });
  }

  Future<void> setStatus(
    String callId,
    CallStatus status,
  ) async {
    final data = <String, dynamic>{
      'status': status.name,
    };

    if (status == CallStatus.connected) {
      data['startedAt'] = FieldValue.serverTimestamp();
    }

    if ({
      CallStatus.ended.name,
      CallStatus.rejected.name,
      CallStatus.missed.name,
      CallStatus.busy.name,
      CallStatus.failed.name,
      CallStatus.disconnected.name,
    }.contains(status.name)) {
      data['endedAt'] = FieldValue.serverTimestamp();
    }

    await _calls.doc(callId).set(
      data,
      SetOptions(merge: true),
    );
  }

  Future<void> endCall(
    String callId,
    int durationSeconds,
  ) async {
    final ref = _calls.doc(callId);
    final snapshot = await ref.get();
    final data = snapshot.data() ?? const <String, dynamic>{};

    var duration = durationSeconds;

    final startedAt = data['startedAt'];
    if (duration <= 0 && startedAt is Timestamp) {
      duration = DateTime.now()
          .difference(startedAt.toDate())
          .inSeconds
          .clamp(0, 86400)
          .toInt();
    }

    var status = CallStatus.ended.name;
    final stored = data['status'];

    if (stored is String &&
        {
          CallStatus.rejected.name,
          CallStatus.missed.name,
          CallStatus.busy.name,
          CallStatus.failed.name,
          CallStatus.disconnected.name,
        }.contains(stored)) {
      status = stored;
    }

    await ref.set({
      'status': status,
      'endedAt': FieldValue.serverTimestamp(),
      'durationSeconds': duration,
    }, SetOptions(merge: true));
  }

  Future<bool> isBlocked({
    required String userId,
    required String targetUserId,
  }) async {
    final snapshot = await _db
        .collection('blockedUsers')
        .doc('${userId}_$targetUserId')
        .get();

    return snapshot.exists;
  }

  Stream<List<CallModel>> history(String uid) {
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
      final list = snapshot.docs
          .map((doc) => CallModel.fromDoc(doc, uid))
          .toList();

      list.sort((a, b) {
        final ad = a.createdAt;
        final bd = b.createdAt;

        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;

        return bd.compareTo(ad);
      });

      return list;
    });
  }

  Future<void> deleteHistoryItem(String callDocId) =>
      _calls.doc(callDocId).delete();

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

    final batch = _db.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
