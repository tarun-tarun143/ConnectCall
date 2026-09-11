@echo off
setlocal
flutter doctor
if errorlevel 1 exit /b 1
flutter create .
if errorlevel 1 exit /b 1
flutter pub get
if errorlevel 1 exit /b 1
flutter analyze
if errorlevel 1 exit /b 1
flutter test
if errorlevel 1 exit /b 1
echo Android project setup complete.
endlocal
