
import 'dart:io';

class AppConfig {
  const AppConfig._();

  static const String appName = 'ConnectCall';
  static const String tagline = 'Connect with anyone, anywhere.';

  static const int zegoAppId = int.fromEnvironment(
    'ZEGO_APP_ID',
    defaultValue: 0,
  );

  static const String zegoAppSign = String.fromEnvironment(
    'ZEGO_APP_SIGN',
    defaultValue: '',
  );

  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: '',
  );

  static const String firebaseAppId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '',
  );

  static const String firebaseMessagingSenderId =
      String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '',
  );

  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: '',
  );

  static const String firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: '',
  );

  static const String firebaseIosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
    defaultValue: 'com.tarun.d.connectCall',
  );

  static bool get hasFirebaseConfig {
    if (Platform.isAndroid) return true;

    return firebaseApiKey.isNotEmpty &&
        firebaseAppId.isNotEmpty &&
        firebaseMessagingSenderId.isNotEmpty &&
        firebaseProjectId.isNotEmpty;
  }

  static bool get hasZegoConfig =>
      zegoAppId > 0 && zegoAppSign.isNotEmpty;

  static bool get isConfigured => hasFirebaseConfig && hasZegoConfig;
}
