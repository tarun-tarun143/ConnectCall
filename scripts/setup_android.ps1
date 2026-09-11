$ErrorActionPreference = 'Stop'
Write-Host 'ConnectCall Android setup' -ForegroundColor Cyan
flutter doctor
flutter create .
flutter pub get
flutter analyze
flutter test
Write-Host 'Android project setup complete.' -ForegroundColor Green
