# ConnectCall UI Upgrade v2

This is a compatibility-corrected UI source pack for the existing ConnectCall project.

Copy the files under `ConnectCall_UI_Upgrade/` into the matching `F:\connect_call\lib\` folders. Do not replace Android, Firebase, ZEGOCLOUD, or other platform/configuration files.

After copying:

```cmd
cd /d F:\connect_call
flutter clean
flutter pub get
flutter analyze
```

The existing app architecture and call integrations are intentionally preserved.
