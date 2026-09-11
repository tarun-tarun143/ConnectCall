
import 'package:firebase_core/firebase_core.dart';

import '../core/config/app_config.dart';

class FirebaseService {
  const FirebaseService._();

  static Future<bool> initialize() async {
    if (Firebase.apps.isNotEmpty) return true;
    if (!AppConfig.hasFirebaseConfig) return false;

    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: AppConfig.firebaseApiKey,
        appId: AppConfig.firebaseAppId,
        messagingSenderId: AppConfig.firebaseMessagingSenderId,
        projectId: AppConfig.firebaseProjectId,
        storageBucket: AppConfig.firebaseStorageBucket.isEmpty
            ? null
            : AppConfig.firebaseStorageBucket,
        iosBundleId: AppConfig.firebaseIosBundleId,
      ),
    );

    return true;
  }
}
