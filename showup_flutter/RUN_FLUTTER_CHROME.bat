@echo off
setlocal
cd /d "%~dp0"

where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter SDK가 설치되어 있지 않거나 PATH에 등록되어 있지 않습니다.
  echo https://docs.flutter.dev/get-started/install/windows 에서 설치하세요.
  pause
  exit /b 1
)

if not exist web (
  echo 웹 실행용 파일을 생성합니다.
  flutter create --platforms=web .
)

flutter pub get
flutter run -d chrome
