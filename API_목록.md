# show up API 목록 (v1)

사용자 앱(`index.html`) + 관리자(`admin.html`) 기준.  
베이스 URL: `https://api.showup.me` (개발: `http://localhost:3000`)

**공통**
- 사용자 API: `Authorization: Bearer <user_jwt>`
- Admin API: `Authorization: Bearer <admin_jwt>` (만료 **8시간**, 비밀번호 **3개월** 강제 변경)
- 에러: `{ error: { code, message } }`

---

## 구현 우선순위

| 순서 | 범위 | API 수 (대략) |
|------|------|---------------|
| 1 | 인증·회원 | §1 |
| 2 | 영상·피드 | §2 |
| 3 | 투표 | §3 |
| 4 | 상금 | §4 |
| 5 | 신고·댓글·소셜 | §5 |
| 6 | Admin 전체 | §A |

---

# 사용자 API (`/api/...`)

## §1 인증·회원

| 메서드 | 경로 | 용도 | 프로토 화면 | 비고 |
|--------|------|------|-------------|------|
| POST | `/api/auth/signup` | 이메일 가입 | 회원가입 | 휴대폰 인증 proof + 약관 동의 필수 |
| GET | `/api/auth/signup/check-email` | 이메일 중복 확인 | 회원가입 | blur 시 |
| GET | `/api/auth/signup/check-login-id` | 아이디 중복 확인 | 회원가입 | blur 시 |
| GET | `/api/auth/signup/check-username` | username 중복 확인 | 회원가입 | blur 시 |
| GET | `/api/auth/signup/check-phone` | 전화번호 중복 확인 | 회원가입 | blur 시 |
| POST | `/api/auth/phone/send-signup` | 가입 전 인증번호 발송 | 회원가입 | 로그인 불필요 |
| POST | `/api/auth/phone/verify-signup` | 가입 전 인증 확인 | 회원가입 | `signupPhoneProof` JWT 반환 |
| POST | `/api/auth/login` | 아이디·비번 로그인 | 로그인 | |
| POST | `/api/auth/logout` | 로그아웃 | 설정 | |
| POST | `/api/auth/password/forgot` | 비밀번호 찾기 1단계 | 비밀번호 찾기 | 본인 확인 |
| POST | `/api/auth/password/reset` | 비밀번호 재설정 | 비밀번호 찾기 | |
| POST | `/api/auth/password/change` | 로그인 중 비밀번호 변경 | 설정 | 현재 비번 + 새 비번 |
| GET | `/api/users/me` | 내 프로필 조회 | 프로필·설정 | |
| PATCH | `/api/users/me` | 프로필 수정 | 프로필 편집 | 닉네임·소개·사진 URL 등 |
| POST | `/api/users/me/confirm-birth` | 생년월일 확인 | 상금 신청 | 만 14 미만 상금 불가 |
| POST | `/api/users/me/avatar/upload-url` | 프로필 사진 업로드 URL | 프로필 | presigned PUT |
| PUT | `/api/users/me/avatar/staging/:storageKey` | 프로필 사진 업로드 | 프로필 | JPEG/PNG/WebP, 5MB |
| POST | `/api/users/me/avatar` | 프로필 사진 확정 | 프로필 | `storageKey` → `avatar_url` |
| POST | `/api/users/me/withdraw` | 탈퇴 요청 | 설정·탈퇴 | `withdraw_pending`, 영상·댓글 삭제 |
| POST | `/api/auth/phone/send` | 인증번호 발송 | 휴대폰 인증 | **상금 신청 전** 게이트 |
| POST | `/api/auth/phone/verify` | 인증번호 확인 | 휴대폰 인증 | |
| POST | `/api/auth/phone/check` | 전화번호 중복 확인 | 상금·휴대폰 인증 | 다른 회원 사용 번호 차단 |
| POST | `/api/auth/identity/pass` | PASS 본인인증 | 상금 신청 | 성인 상금 전 필수 |
| POST | `/api/auth/guardian/pass` | 보호자 PASS (구) | — | **레거시** · 앱 미사용 |
| POST | `/api/auth/guardian/request` | 보호자 PASS 링크 발송 | 상금·보호자 | 만 14~16세 · `script.js` |
| GET | `/api/auth/guardian/status` | 보호자 인증 상태 | 상금·보호자 | 폴링 · `script.js` |
| GET | `/api/auth/guardian/session/:token` | 보호자 페이지 세션 | `guardian-verify.html` | JWT 불필요 |
| POST | `/api/auth/guardian/session/:token/pass` | 보호자 PASS 완료 | `guardian-verify.html` | 보호자 **본인 폰** |

**미성년(14~16세) 보호자 인증 흐름**  
`request` → 보호자 휴대폰에서 링크 오픈 → `session/:token/pass` → 앱 `status` 폴링

---

## §2 영상·피드·업로드

| 메서드 | 경로 | 용도 | 프로토 화면 | 비고 |
|--------|------|------|-------------|------|
| GET | `/api/feed` | 홈 피드 | 홈·릴스 | `public` 영상만 |
| GET | `/api/home-feed` | 홈 피드 (별칭) | 홈·릴스 | `/api/feed` 와 동일 · `script.js` |
| GET | `/api/videos/:id` | 영상 상세 | 피드·프로필 뷰어 | |
| GET | `/api/users/:handle/videos` | 사용자 영상 목록 | 프로필 | 본인: `hidden` 포함 |
| POST | `/api/videos/upload-url` | 업로드 URL 발급 | DROP·카메라 | S3 등 presigned |
| PUT | `/api/videos/staging/:storageKey` | 스테이징 파일 업로드 | DROP·카메라 | **개발용** · `script.js` |
| POST | `/api/videos` | 업로드 완료 등록 | DROP | → `ai_pending` |
| PATCH | `/api/videos/:id` | 내 영상 수정 | 프로필 ··· 수정 | 제목·음원 · `script.js` |
| GET | `/api/videos/:id/status` | AI 검수 상태 | 업로드 후 | 폴링 |
| DELETE | `/api/videos/:id` | 내 영상 삭제 | 프로필 | 본인만 |
| GET | `/api/music/tracks` | 음원 목록 | DROP 음원 선택 | v1 mock 가능 |
| POST | `/api/videos/:id/like` | 좋아요 | 피드 | 토글 |
| DELETE | `/api/videos/:id/like` | 좋아요 취소 | 피드 | |
| GET | `/api/ranking` | 랭킹 100 | 랭킹 탭 | 조회·좋아요·댓글 노출용 |

---

## §3 투표·챌린지

| 메서드 | 경로 | 용도 | 프로토 화면 | 비고 |
|--------|------|------|-------------|------|
| GET | `/api/challenges/current` | 현재 주차·`phase` | 투표 탭 | KST 자동 |
| GET | `/api/challenges/current/candidates` | 후보 목록 | 투표 | phase별 5명/3명 |
| POST | `/api/challenges/current/votes` | 투표 | 투표 확인 | 1인 1표, IP 기록 |
| DELETE | `/api/challenges/current/votes` | 투표 취소 | 투표 | 기간 내 |
| GET | `/api/challenges/current/results` | TOP·우승 결과 | 투표·알림 | 확정 후 |
| GET | `/api/challenges/current/prediction` | 내 예측 조회 | 예측 탭 | |
| POST | `/api/challenges/current/prediction` | 예측 제출 | 예측 탭 | 확정 후 수정 불가 |

**`phase` 값 (읽기 전용)**  
`idle` → `general_open` → `general_closed` → `top10_open` → `top10_closed` → `final_open` → `final_closed` → `top10_confirmed` → `top3_confirmed` → `winners_confirmed`

---

## §4 상금

| 메서드 | 경로 | 용도 | 프로토 화면 | 비고 |
|--------|------|------|-------------|------|
| GET | `/api/payouts/me` | 내 상금 상태 | 상금·알림 | |
| POST | `/api/payouts/:id/claim` | 수령 신청 | 상금 신청 폼 | 전화·PASS·보호자 게이트 |
| GET | `/api/payouts/:id/tax-guide` | 제세공과금 안내 | 상금 | **앱 내 안내** |

**`payouts.status`**  
`pending_claim` → `claimed` → `reviewing` → `on_hold` → `approved` → `paid` / `expired`

---

## §5 댓글·신고·관심·차단·알림·검색

| 메서드 | 경로 | 용도 | 프로토 화면 | 비고 |
|--------|------|------|-------------|------|
| GET | `/api/videos/:id/comments` | 댓글 목록 | 댓글 시트 | |
| POST | `/api/videos/:id/comments` | 댓글 작성 | 댓글 | |
| DELETE | `/api/comments/:id` | 내 댓글 삭제 | 댓글 ··· | |
| POST | `/api/reports` | 신고 접수 | 영상·댓글·계정 신고 | `target_type` |
| POST | `/api/users/:handle/interest` | 관심 추가 | 프로필 | 팔로우 아님 |
| DELETE | `/api/users/:handle/interest` | 관심 해제 | 프로필 | |
| GET | `/api/users/:handle/interests` | 관심 목록 | 프로필·관심 탭 | |
| POST | `/api/users/:handle/block` | 차단 | 프로필 ··· | |
| DELETE | `/api/users/:handle/block` | 차단 해제 | 설정·차단 목록 | |
| GET | `/api/users/blocks` | 차단 목록 | 설정 | |
| GET | `/api/notifications` | 알림 목록 | 알림 | |
| PATCH | `/api/notifications/:id/read` | 읽음 처리 | 알림 | |
| GET | `/api/search` | 통합 검색 | 검색 | `?q=&type=user\|video` |
| GET | `/api/users/:handle` | 타인 프로필 | 프로필 | 차단 시 403 |

---

## §6 설정·기타 (v1)

| 메서드 | 경로 | 용도 | 프로토 화면 | 비고 |
|--------|------|------|-------------|------|
| GET | `/api/users/me/settings` | 알림·품질 등 설정 | 설정 | |
| PATCH | `/api/users/me/settings` | 설정 저장 | 설정 토글 | |
| POST | `/api/support/report-problem` | 문제 신고 | 설정·도움말 | 선택 |

**v2 이후 (프로토만 있음, v1 API 생략 가능)**  
예측(BET)·쿠폰·광고 이벤트·DM·저장(북마크)

---

# 관리자 API (`/api/admin/...`)

## §A1 인증

| 메서드 | 경로 | 용도 | 프로토 | 비고 |
|--------|------|------|--------|------|
| POST | `/api/admin/auth/login` | 로그인 | admin 로그인 | 번호+비번 · `admin.js` · 데모 `1234`/`1234` |
| GET | `/api/admin/auth/me` | 로그인 상태 확인 | admin 로그인 | 세션 복원 · `admin.js` |
| POST | `/api/admin/auth/logout` | 로그아웃 | admin 상단 · `admin.js` |
| POST | `/api/admin/auth/change-password` | 비밀번호 변경 | 관리자 권한 · `admin.js` | **3개월** 주기 |

---

## §A2 대시보드

| 메서드 | 경로 | 용도 | 프로토 |
|--------|------|------|--------|
| GET | `/api/admin/dashboard/summary` | 처리할 일 집계 | dashboard · `admin.js` |

응답 예: `{ videosPending, reportsOpen, commentsFlagged, voteConfirmPending, payoutsReviewing }`

---

## §A3 영상 검수

| 메서드 | 경로 | 용도 | 프로토 버튼 |
|--------|------|------|-------------|
| GET | `/api/admin/videos` | 검수 대기 목록 | videos · `admin.js` |
| POST | `/api/admin/videos/:id/approve` | 관리자 승인 | 관리자 승인 · `admin.js` |
| POST | `/api/admin/videos/:id/reject` | 관리자 반려 | 관리자 반려 · `admin.js` |

**`videos.status`**  
`ai_pending` | `public` | `ai_review` | `approved` | `rejected` | `hidden` | `delete_pending` | `deleted`  
`hidden` = 타인 비공개, **작성자 마이페이지에는 표시**

---

## §A4 신고·댓글

| 메서드 | 경로 | 용도 | 프로토 |
|--------|------|------|--------|
| GET | `/api/admin/reports` | 신고 목록 | reports · `admin.js` |
| POST | `/api/admin/reports/:id/resolve` | 신고 처리 | 8종 버튼 · `admin.js` |
| GET | `/api/admin/comments` | 댓글 검토 목록 | comments · `admin.js` |
| POST | `/api/admin/comments/:id/moderate` | 댓글 처리 | 삭제·숨김·유지 · `admin.js` |

**신고 resolve `action`**  
`dismiss` | `hide_video` | `delete_video` | `delete_comment` | `warn_user` | `suspend_user` | `ban_user` | `review_more`

---

## §A5 투표 관리

| 메서드 | 경로 | 용도 | 프로토 | 비고 |
|--------|------|------|--------|------|
| GET | `/api/admin/challenges/current` | phase·일정 | vote · `admin.js` | 읽기 |
| GET | `/api/admin/challenges/current/candidates` | TOP20 후보 | vote · `admin.js` | 투표수만 |
| POST | `/api/admin/challenges/current/confirm` | 확정 | voteSteps · `admin.js` | `step` + **`excludeUserIds`** (후보 제외 체크) |
| POST | `/api/admin/challenges/current/votes/invalidate` | 부정투표 제거 | vote step 3 · `admin.js` | **동일 IP** 기준 |

**phase 변경:** KST **cron 자동** (Admin 수동 시작/종료 버튼 없음)

**confirm `step`**
| step | 동작 |
|------|------|
| `top10` | TOP10 확정 |
| `top3` | TOP3 확정 |
| `winners` | 1·2·3등 확정 → payouts 생성 |

---

## §A6 상금 지급

| 메서드 | 경로 | 용도 | 프로토 버튼 |
|--------|------|------|-------------|
| GET | `/api/admin/payouts` | 상금 목록 | payouts | 보호자·예금주 검토 포함 · `admin.js` |
| POST | `/api/admin/payouts/:id/notify` | 수령 알림 | 알림 발송 | `admin.js` |
| POST | `/api/admin/payouts/:id/hold` | 지급 보류 | 보류 | `on_hold` · `admin.js` |
| POST | `/api/admin/payouts/:id/resume-review` | 보류 해제 | 검토 재개 | `reviewing` · `admin.js` |
| POST | `/api/admin/payouts/:id/approve` | 지급 승인 | 지급 승인 | `admin.js` |
| POST | `/api/admin/payouts/:id/mark-paid` | 지급 완료 | 지급 완료 | `admin.js` |
| POST | `/api/admin/payouts/:id/expire` | 만료 | 만료 | `admin.js` |
| PATCH | `/api/admin/payouts/:id/review-step` | 검토 단계 | 8단계 체크 | **UI 미연결** (표시만) |

**`review_step` 0~7**  
0수령신청 → 1본인 → 2계좌 → 3부정참여 → 4보호자 → 5제세공과금 → 6승인 → 7완료

---

## §A7 회원 관리

| 메서드 | 경로 | 용도 | 프로토 버튼 |
|--------|------|------|-------------|
| GET | `/api/admin/users` | 회원 목록 | users · `admin.js` |
| GET | `/api/admin/users/:id` | 회원 상세 | 상세 · `admin.js` |
| POST | `/api/admin/users/:id/suspend` | 일시 정지 | 정지 · `admin.js` |
| POST | `/api/admin/users/:id/ban` | 영구 정지 | 영구정지 · `admin.js` (super) |
| POST | `/api/admin/users/:id/withdraw` | 탈퇴 처리 | 탈퇴 처리 · `admin.js` |

---

## §A8 공통 (모든 Admin 쓰기 API)

| 항목 | 내용 |
|------|------|
| `admin_logs` | 모든 POST/PATCH 후 기록 필수 |
| 권한 v1 | **super** 1계정만 |
| JWT | 8시간 만료 |

---

# 요약 카운트

| 구분 | v1 API 수 |
|------|-----------|
| 사용자 | **약 58개** |
| 관리자 | **약 26개** |
| **합계** | **약 84개** |

---

# 프로토타입 화면 ↔ API 연결 (2026-06 · 1단계 테스트 완료)

## 연결 현황 요약

| 화면 / 파일 | 상태 | 비고 |
|-------------|------|------|
| `index.html` + `script.js` | ✅ 연결 | 사용자 API 대부분 · 서버 실패 시 mock 폴백 |
| `guardian-verify.html` + `guardian-verify.js` | ✅ 연결 | 보호자 PASS 전용 |
| `admin.html` + `admin.js` | ✅ 연결 | 7개 메뉴 + 로그인 · 데모 `1234`/`1234` |
| Admin 로그아웃·비밀번호 변경 | ✅ 연결 | `admin.js` |
| Admin `review-step` | ⬜ 미연결 | 8단계 UI는 표시만 |

---

## `script.js` (사용자 앱)

| API | 용도 |
|-----|------|
| `POST /api/auth/signup` | 회원가입 |
| `GET /api/auth/signup/check-*` | 이메일·아이디·username 중복 확인 |
| `POST /api/auth/phone/send-signup` | 가입 전 휴대폰 인증 발송 |
| `POST /api/auth/phone/verify-signup` | 가입 전 휴대폰 인증 확인 |
| `POST /api/auth/login` | 로그인 |
| `POST /api/auth/logout` | 로그아웃 |
| `POST /api/auth/password/forgot` | 비밀번호 찾기 |
| `POST /api/auth/password/reset` | 비밀번호 재설정 |
| `POST /api/auth/password/change` | 설정 · 비밀번호 변경 |
| `POST /api/auth/phone/send` | 인증번호 발송 |
| `POST /api/auth/phone/verify` | 인증번호 확인 |
| `POST /api/auth/phone/check` | 전화번호 중복 확인 (상금) |
| `POST /api/auth/identity/pass` | PASS 본인인증 (상금) |
| `POST /api/auth/guardian/request` | 보호자 PASS 링크 |
| `GET /api/auth/guardian/status` | 보호자 인증 폴링 |
| `GET /api/users/me` | 내 프로필 |
| `PATCH /api/users/me` | 프로필 수정 |
| `POST /api/users/me/confirm-birth` | 상금 전 생년월일 확인 |
| `POST /api/users/me/avatar/upload-url` | 프로필 사진 업로드 URL |
| `PUT /api/users/me/avatar/staging/:storageKey` | 프로필 사진 업로드 |
| `POST /api/users/me/avatar` | 프로필 사진 확정 |
| `POST /api/users/me/withdraw` | 탈퇴 |
| `GET /api/users/me/settings` | 설정 조회 |
| `PATCH /api/users/me/settings` | 설정 저장 |
| `GET /api/home-feed` | 홈 피드 |
| `GET /api/ranking` | 랭킹 |
| `GET /api/videos/:id` | 영상 상세 |
| `GET /api/videos/:id/status` | AI 검수 폴링 |
| `POST /api/videos/upload-url` | 업로드 URL |
| `PUT /api/videos/staging/:storageKey` | 스테이징 업로드 (개발) |
| `POST /api/videos` | 업로드 등록 |
| `PATCH /api/videos/:id` | 영상 수정 |
| `DELETE /api/videos/:id` | 영상 삭제 |
| `POST/DELETE /api/videos/:id/like` | 좋아요 |
| `GET /api/music/tracks` | 음원 목록 |
| `GET /api/users/:handle` | 타인 프로필 |
| `GET /api/users/:handle/videos` | 사용자 영상 |
| `GET /api/challenges/current` | 투표 phase |
| `GET /api/challenges/current/candidates` | 투표 후보 |
| `GET /api/challenges/current/results` | 투표 결과 |
| `GET/POST /api/challenges/current/prediction` | 예측 조회·제출 |
| `POST/DELETE /api/challenges/current/votes` | 투표·취소 |
| `GET /api/payouts/me` | 내 상금 |
| `GET /api/payouts/:id/tax-guide` | 제세공과금 안내 |
| `POST /api/payouts/:id/claim` | 상금 신청 |
| `GET/POST /api/videos/:id/comments` | 댓글 |
| `DELETE /api/comments/:id` | 댓글 삭제 |
| `POST /api/reports` | 신고 |
| `POST/DELETE /api/users/:handle/interest` | 관심 |
| `GET /api/users/:handle/interests` | 관심 목록 |
| `POST/DELETE /api/users/:handle/block` | 차단 |
| `GET /api/users/blocks` | 차단 목록 |
| `GET /api/notifications` | 알림 |
| `PATCH /api/notifications/:id/read` | 읽음 |
| `GET /api/search` | 검색 |
| `POST /api/support/report-problem` | 문제 신고 |

> `GET /api/feed` 는 `/api/home-feed` 별칭으로 **동일 동작** · 앱은 `home-feed` 사용

---

## `guardian-verify.js` (보호자 PASS)

| API | 용도 |
|-----|------|
| `GET /api/auth/guardian/session/:token` | 세션 조회 |
| `POST /api/auth/guardian/session/:token/pass` | 보호자 PASS 완료 |

---

## `admin.js` (관리자)

| API | 메뉴 / 동작 |
|-----|-------------|
| `POST /api/admin/auth/login` | 로그인 |
| `GET /api/admin/auth/me` | 세션 복원 |
| `POST /api/admin/auth/logout` | 로그아웃 |
| `POST /api/admin/auth/change-password` | 비밀번호 변경 |
| `GET /api/admin/dashboard/summary` | 대시보드 건수 |
| `GET /api/admin/videos` | 영상 검수 목록 |
| `POST /api/admin/videos/:id/approve` | 승인 |
| `POST /api/admin/videos/:id/reject` | 반려 |
| `GET /api/admin/reports` | 신고 목록 (`status=open`) |
| `POST /api/admin/reports/:id/resolve` | 신고 8종 처리 |
| `GET /api/admin/comments` | 댓글 (`flagged=1`) |
| `POST /api/admin/comments/:id/moderate` | 댓글 삭제·숨김·유지 |
| `GET /api/admin/challenges/current` | 투표 phase |
| `GET /api/admin/challenges/current/candidates` | TOP20 |
| `POST /api/admin/challenges/current/confirm` | TOP10/TOP3/우승 확정 · `excludeUserIds` |
| `POST /api/admin/challenges/current/votes/invalidate` | 부정투표 제거 |
| `GET /api/admin/payouts` | 상금 목록·검토 패널 |
| `POST /api/admin/payouts/:id/notify` | 알림 발송 |
| `POST /api/admin/payouts/:id/hold` | 보류 |
| `POST /api/admin/payouts/:id/resume-review` | 검토 재개 |
| `POST /api/admin/payouts/:id/approve` | 지급 승인 |
| `POST /api/admin/payouts/:id/mark-paid` | 지급 완료 |
| `POST /api/admin/payouts/:id/expire` | 만료 |
| `GET /api/admin/users` | 회원 목록·검색 |
| `GET /api/admin/users/:id` | 상세 |
| `POST /api/admin/users/:id/suspend` | 정지 |
| `POST /api/admin/users/:id/ban` | 영구정지 |
| `POST /api/admin/users/:id/withdraw` | 탈퇴 처리 |

---

## API만 있고 화면 미연결

| API | 비고 |
|-----|------|
| `PATCH /api/admin/payouts/:id/review-step` | 8단계 줄은 표시만 (의도적 생략) |
| `POST /api/auth/guardian/pass` | 레거시 · 앱 미사용 |

---

# 사용자 ↔ Admin 대응

| 사용자 API | Admin API |
|------------|-----------|
| `POST /api/videos` | `GET /api/admin/videos` → approve/reject |
| `POST /api/reports` | `POST /api/admin/reports/:id/resolve` |
| `POST /api/.../comments` | `POST /api/admin/comments/:id/moderate` |
| `POST /api/challenges/.../votes` | `GET candidates` → confirm / invalidate |
| `POST /api/payouts/:id/claim` | `GET /api/admin/payouts` → hold/approve/mark-paid |
| `POST /api/auth/guardian/request` + `session/:token/pass` | `GET /api/admin/payouts` · review.guardian |
| `POST /api/users/me/withdraw` | `POST /api/admin/users/:id/withdraw` |

---

*작성: 2026-06 · 1단계 테스트 완료 · 어드민 전 메뉴 API 연결 · 데모 admin `1234`/`1234`*
