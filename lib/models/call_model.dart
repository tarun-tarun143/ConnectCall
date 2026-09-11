import 'package:cloud_firestore/cloud_firestore.dart';

enum CallType { audio, video, group }

enum CallStatus {
  ringing,
  connected,
  ended,
  rejected,
  missed,
  busy,
  failed,
  disconnected,
}

class CallModel {
  final String id;
  final String peerId;
  final String peerName;
  final String callType;
  final String direction;
  final String status;
  final int durationSeconds;
  final DateTime? createdAt;

  const CallModel({
    required this.id,
    required this.peerId,
    required this.peerName,
    required this.callType,
    required this.direction,
    required this.status,
    required this.durationSeconds,
    this.createdAt,
  });

  factory CallModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return CallModel(
      id: doc.id,
      peerId: _string(data['peerId'] ?? data['calleeId'] ?? data['callerId']),
      peerName: _string(data['peerName'] ?? data['calleeName'] ?? data['callerName'], fallback: 'Unknown user'),
      callType: _string(data['callType'] ?? data['type'], fallback: 'audio'),
      direction: _string(data['direction'], fallback: 'outgoing'),
      status: _string(data['status'], fallback: 'ended'),
      durationSeconds: (data['durationSeconds'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory CallModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String currentUid,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final callerId = _string(data['callerId']);
    final calleeId = _string(data['calleeId']);
    final incoming = calleeId == currentUid && callerId != currentUid;
    final peerId = incoming ? callerId : calleeId;
    final peerName = incoming
        ? _string(data['callerName'], fallback: 'Unknown user')
        : _string(data['calleeName'], fallback: 'Unknown user');

    return CallModel(
      id: doc.id,
      peerId: peerId,
      peerName: peerName,
      callType: _string(data['type'] ?? data['callType'], fallback: 'audio'),
      direction: incoming ? 'incoming' : 'outgoing',
      status: _string(data['status'], fallback: 'ended'),
      durationSeconds: (data['durationSeconds'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  static String _string(Object? value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }
}
