@echo off
echo ====================================================
echo Starting Savora Flutter App on Google Chrome...
echo ====================================================
cd /d "%~dp0"
flutter run -d chrome --web-port=5000
pause

