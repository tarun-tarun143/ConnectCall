# ConnectCall — Android Studio + Firebase + ZEGOCLOUD setup

## 1. Android Studio

Install Android Studio with the Android SDK and Android SDK Platform Tools. Install the Flutter and Dart plugins from Android Studio's Plugins settings.

Open `F:\connectcall` in Android Studio. In the Android Studio Terminal run:

```powershell
flutter doctor
flutter create .
flutter pub get
flutter analyze
flutter test
```

The repository contains the application source and application-specific native configuration. `flutter create .` generates the Flutter/Gradle wrapper files for the exact Flutter SDK installed on your machine, which avoids pinning an obsolete Gradle wrapper into the repository.

## 2. ZEGOCLOUD

ZEGOCLOUD project:

```text
Project: ConnectCall
AppID: 503220443
```

From **ZEGOCLOUD Console → Projects Management → ConnectCall → Project Information**, copy your **AppSign** locally.

Never put `ServerSecret` or `CallbackSecret` into the Flutter app and never commit them to git.

The Flutter Call Kit and Signaling Plugin versions in this project are:

```text
zego_uikit_prebuilt_call: ^4.24.4
zego_uikit_signaling_plugin: ^2.8.21
```

## 3. Firebase

Create/select your Firebase project and register the Android application. Enable:

- Authentication → Email/Password
- Cloud Firestore
- Cloud Messaging

The app uses build-time Dart defines rather than committing Firebase credentials into source code.

Required values:

```text
FIREBASE_API_KEY
FIREBASE_APP_ID
FIREBASE_MESSAGING_SENDER_ID
FIREBASE_PROJECT_ID
FIREBASE_STORAGE_BUCKET (optional)
```

## 4. Run from Android Studio

PowerShell example:

```powershell
flutter run --dart-define="ZEGO_APP_ID=503220443" --dart-define="ZEGO_APP_SIGN=YOUR_APPSIGN" --dart-define="FIREBASE_API_KEY=YOUR_FIREBASE_API_KEY" --dart-define="FIREBASE_APP_ID=YOUR_FIREBASE_APP_ID" --dart-define="FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID" --dart-define="FIREBASE_PROJECT_ID=YOUR_PROJECT_ID" --dart-define="FIREBASE_STORAGE_BUCKET=YOUR_BUCKET"
```

Do not paste real credentials into README or source files.

## 5. Firestore

Deploy the included rules and indexes after installing Firebase CLI and logging into the correct Firebase project:

```powershell
firebase deploy --only firestore
```

## 6. ZEGOCLOUD online and offline invitations

The app initializes `ZegoUIKitPrebuiltCallInvitationService` after a successful Firebase login and uninitializes it on logout. The Android app includes microphone, camera, notification, vibration and related modern calling permissions.

For background/killed-app incoming-call behavior, complete the current ZEGOCLOUD offline-call and push-notification configuration in the ZEGOCLOUD Console and Firebase Console. This is provider configuration in addition to the Dart code.

## 7. Two-device testing

Use two physical Android phones for the strongest test:

1. Create two Firebase accounts.
2. Install ConnectCall on both devices.
3. Sign in as user A on device 1 and user B on device 2.
4. Confirm both users appear online.
5. Start an audio call.
6. Accept on the second phone.
7. Test microphone, speaker and end-call controls.
8. Repeat with video.
9. Test camera off/on and front/rear switch.
10. Test reject, timeout, blocked user and permission-denied cases.
11. Check call history.
12. Test group calling with at least two invitees plus the caller.

## 8. Release APK

After `flutter analyze` and `flutter test` succeed:

```powershell
flutter clean
flutter pub get
flutter build apk --release --dart-define="ZEGO_APP_ID=503220443" --dart-define="ZEGO_APP_SIGN=YOUR_APPSIGN" --dart-define="FIREBASE_API_KEY=YOUR_FIREBASE_API_KEY" --dart-define="FIREBASE_APP_ID=YOUR_FIREBASE_APP_ID" --dart-define="FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID" --dart-define="FIREBASE_PROJECT_ID=YOUR_PROJECT_ID" --dart-define="FIREBASE_STORAGE_BUCKET=YOUR_BUCKET"
```

APK:

```text
build\app\outputs\flutter-apk\app-release.apk
```

## 9. Optional backend

The included Node.js backend is optional for normal ZEGOCLOUD calling. It provides a health endpoint and an optional Firebase Admin FCM sender.

```powershell
cd backend
npm install
npm start
```

Health check:

```powershell
curl http://localhost:8080/health
```

The backend does not require your ZEGOCLOUD ServerSecret for the normal Call Kit flow.
