
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/routing/app_navigator.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    if (Platform.isAndroid) {
      await Firebase.initializeApp();
    } else if (AppConfig.hasFirebaseConfig) {
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
    }
  }

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  ZegoUIKitPrebuiltCallInvitationService()
      .setNavigatorKey(appNavigatorKey);

  runApp(
    const ProviderScope(
      child: ConnectCallApp(),
    ),
  );
}
