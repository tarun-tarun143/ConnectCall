ConnectCall Calling UI Upgrade

Files:
- zego_service.dart -> replaces lib/services/zego_service.dart
- call_page.dart -> replaces lib/screens/call/call_page.dart

This upgrade keeps the existing Firebase, Firestore, ZEGOCLOUD invitation flow, call history callbacks, and call IDs intact.

UI improvements:
- Dark ConnectCall calling background with indigo glow
- Polished incoming/outgoing invitation presentation
- Avatar/name/calling status on invitation UI
- Persistent dark in-call control bar
- Audio: microphone, speaker/audio output, end call
- Video: microphone, camera, speaker/audio output, camera switch, end call
- Audio/video view labels and avatar/waveform states
- Video uses aspect-fill rendering

After copying the files, run:
cd /d F:\connect_call
flutter clean
flutter pub get
flutter analyze
flutter run -d 10BE6D1ZGA000T8 --dart-define=ZEGO_APP_ID=YOUR_APP_ID --dart-define=ZEGO_APP_SIGN=YOUR_APP_SIGN
