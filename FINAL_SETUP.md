# ConnectCall final setup

This source tree is aligned to the reported Flutter analyzer errors and the ZEGOCLOUD 4.24.4 API.

## Dependency compatibility

- zego_uikit_prebuilt_call: ^4.24.4
- zego_uikit: 2.28.47
- zego_uikit_signaling_plugin: ^2.8.21
- permission_handler: ^12.0.3
- connectivity_plus: ^6.1.5
- flutter_riverpod: ^3.4.3

## Android Studio

Open the folder in Android Studio and run:

```text
flutter create .
flutter pub get
flutter analyze
flutter test
```

The `flutter create .` command regenerates the Android/Gradle platform wrapper for the Flutter SDK installed on the development machine.

## Required runtime configuration

Use Dart defines for Firebase and ZEGOCLOUD. Do not commit AppSign, ServerSecret, Firebase service-account private keys, or other secrets.

Example:

```text
flutter run --dart-define="ZEGO_APP_ID=503220443" --dart-define="ZEGO_APP_SIGN=YOUR_REAL_APPSIGN" --dart-define="FIREBASE_API_KEY=YOUR_REAL_FIREBASE_API_KEY" --dart-define="FIREBASE_APP_ID=YOUR_REAL_FIREBASE_APP_ID" --dart-define="FIREBASE_MESSAGING_SENDER_ID=YOUR_REAL_SENDER_ID" --dart-define="FIREBASE_PROJECT_ID=YOUR_REAL_PROJECT_ID"
```
