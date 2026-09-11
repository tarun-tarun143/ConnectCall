class ZegoIds {
  ZegoIds._();

  static String fromFirebaseUid(String firebaseUid) {
    final cleaned = firebaseUid.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
    final safe = cleaned.length > 28 ? cleaned.substring(0, 28) : cleaned;
    return 'u_$safe';
  }
}
