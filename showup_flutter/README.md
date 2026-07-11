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

## API 연결 (B 단계)

`lib/api/` 폴더에서 showup-server와 통신합니다.

| 기능 | API |
|------|-----|
| 로그인/회원가입/로그아웃 | `/api/auth/*` |
| 홈 피드 | `GET /api/home-feed` |
| 랭킹 | `GET /api/ranking` |
| 투표 | `GET/POST/DELETE /api/challenges/current/*` |
| 예측 | `GET/POST /api/challenges/current/prediction` |
| 좋아요 | `POST/DELETE /api/videos/:id/like` |

- **개발 서버:** `http://localhost:3000` (showup-server)
- **운영:** `https://api.showup.me`
- 서버가 꺼져 있으면 **샘플 데이터로 자동 폴백** (웹 `script.js` 와 같음)
- 로그인 JWT는 `shared_preferences`에 저장

서버 켜기: showup-server 저장소에서 `npm start` (포트 3000)

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
  main.dart           앱 시작 + 탭 + API 연결
  api/
    api_client.dart   HTTP + Bearer 토큰
    auth_session.dart JWT 저장
    showup_api.dart   로그인·피드·투표·예측·랭킹
    mock_data.dart    서버 없을 때 샘플 데이터
  auth_screens.dart   로그인/회원가입
  home_screen.dart    홈 피드
  camera_screen.dart  DROP
  vote_screen.dart    투표
  bet_screen.dart     예측
  rank_screen.dart    랭킹
  profile_screen.dart 프로필
  settings_screen.dart 설정
  overlays.dart       릴스/댓글/알림
  extra_modals.dart   공유/QR/상금/보호자/약관 등
```

## 아직 연결 전

- 실제 카메라 SDK
- 영상 업로드 (`POST /api/videos/upload-url` 등)
- 댓글·알림·상금 상세 API
