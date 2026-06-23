@echo off
setlocal
cd /d "%~dp0"

where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter SDK가 설치되어 있지 않거나 PATH에 등록되어 있지 않습니다.
  echo 먼저 Flutter를 설치한 뒤 이 파일을 다시 실행하세요.
  pause
  exit /b 1
)

if not exist android (
  echo Android/iOS 플랫폼 폴더를 생성합니다.
  flutter create --platforms=android,ios .
)

flutter pub get
flutter run
