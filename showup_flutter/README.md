# show up Flutter prototype

웹 프로토타입(`index.html`)을 Flutter로 옮긴 앱 UI입니다.

## 포함 화면

- 인트로, 로그인, 회원가입, 비밀번호 찾기
- Home 피드, HOT 릴스, 댓글, 알림
- DROP 카메라 (UI 프로토타입)
- Vote 투표
- Predict 예측
- Ranking 랭킹
- Profile, Settings

아직 서버 API / 실제 카메라 / 실제 업로드는 연결 전입니다.

## 실행 (Windows · Chrome 추천)

1. Flutter 설치: https://docs.flutter.dev/get-started/install/windows
2. 명령 프롬프트에서 이 폴더로 이동
3. `RUN_FLUTTER_CHROME.bat` 더블클릭

또는 수동:

```bat
cd showup_flutter
flutter create --platforms=web .
flutter pub get
flutter run -d chrome
```

## 아이폰 크기로 보기

크롬 실행 후 `F12` → 휴대폰 아이콘 → iPhone 선택

## 파일 구조

```
lib/
  main.dart           앱 시작 + 탭 연결
  auth_screens.dart   로그인/회원가입
  home_screen.dart    홈 피드
  camera_screen.dart  DROP
  vote_screen.dart    투표
  bet_screen.dart     예측
  rank_screen.dart    랭킹
  profile_screen.dart 프로필
  settings_screen.dart 설정
  overlays.dart       릴스/댓글/알림
```
