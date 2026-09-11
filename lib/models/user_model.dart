import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/zego_ids.dart';

class UserModel {
  final String id;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String bio;
  final String zegoId;
  final bool online;
  final String status;
  final String avatarUrl;
  final String photoUrl;
  final bool isVerified;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.bio,
    required this.zegoId,
    required this.online,
    required this.status,
    required this.avatarUrl,
    required this.photoUrl,
    required this.isVerified,
    this.updatedAt,
  });

  factory UserModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final name = _string(data['name']);
    final storedZegoId = _string(data['zegoId']);
    final photo = _string(data['photoUrl']);
    final avatar = _string(data['avatarUrl']);

    return UserModel(
      id: doc.id,
      name: name.isEmpty ? 'User' : name,
      username: _string(data['username']),
      email: _string(data['email']),
      phone: _string(data['phone']),
      bio: _string(data['bio']),
      zegoId: storedZegoId.isEmpty
          ? ZegoIds.fromFirebaseUid(doc.id)
          : storedZegoId,
      online: data['online'] == true,
      status: _string(data['status'], fallback: 'available'),
      avatarUrl: avatar.isNotEmpty ? avatar : photo,
      photoUrl: photo.isNotEmpty ? photo : avatar,
      isVerified: data['isVerified'] == true,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  static String _string(Object? value, {String fallback = ''}) {
    if (value is String) return value.trim();
    return fallback;
  }
}
