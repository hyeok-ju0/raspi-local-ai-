# 2026-09-23 작업 기록: 보안·기능 소프트웨어 — 화면 잠금, 로그 자동 삭제, 클립보드 초기화

RAG 데이터 gocryptfs 암호화(지난 세션)에 이어, 우선순위 2에 남아있던 나머지 3개
항목을 구현했다.

## 1. 휴대 모드 화면/세션 잠금

### 도구 선택
- Wayland/labwc 환경에 맞는 화면 잠금 도구로 `swaylock` + `swayidle` 채택
- 사전 조사: labwc 공식 저장소가 `ext-session-lock-v1` 프로토콜을 지원한다고
  명시, swaylock도 이 프로토콜(또는 `wlr-layer-shell`+`wlr-input-inhibitor`)
  중 하나만 있으면 호환됨을 확인 — 실제로 두 패키지 모두 OS 이미지에 이미
  설치되어 있었음(`swaylock 1.8.2-1+rpt4`, `swayidle 1.8.0-1+b1`)

### 설계
- 잠금 해제: 로그인 비밀번호(PAM 기본 인증) — 별도 설정 불필요
- 자동 잠금: **휴대 모드에서만**, 10분 무작동 시(거치 모드는 잠금 없음)
- 수동 즉시 잠금: `lock-screen` alias 추가

### 구현
`~/.config/labwc/autostart`에 추가:
```bash
if [ "$(cat /etc/cyberdeck_mode 2>/dev/null)" = "portable" ]; then
  swayidle -w timeout 600 'swaylock -f' &
fi
```
`~/.bashrc`: `alias lock-screen='swaylock -f'`

### 검증 상태
파일 반영까지 완료, **실제 기기 화면에서의 동작(잠금 화면 표시, 비밀번호로
해제, 터치스크린에서 입력 가능 여부)은 아직 미검증** — SSH로는 확인 불가,
다음 세션에서 실기기 앞에서 확인 필요.

## 2. 로그 자동 삭제/만료 관리

### 범위 결정
Open WebUI 대화 기록(Docker SQLite DB, API 조사 필요, 계정별 구분 필요, 실수
시 복구 어려움)은 이번엔 제외하고, 우리가 만든 `~/.ai_history/archive/`
(휴대·거치 터미널 대화 기록, 단순 JSON 파일이라 안전하게 다룰 수 있음)만
우선 대상으로 함.

### 구현
- `~/cleanup_ai_history.sh`: `find`로 30일 지난 `.json` 파일 삭제
- systemd 사용자 타이머(`ai-history-cleanup.timer`, `.service`)로 매일 자정 실행
- `loginctl enable-linger hyeogju`로 로그인 세션 없어도 타이머 유지되도록 설정

### 검증 상태
타이머 등록·`list-timers` 확인·수동 실행("0개 파일 삭제됨") 전부 정상 확인.
`Linger=yes` 확인 완료. **완전히 검증됨.**

## 3. 클립보드 자동 초기화

### 도구
Wayland 클립보드 관리 도구 `wl-clipboard`(`wl-copy`/`wl-paste`) 설치.

### 설계
- 복사 후 2분 지나도 내용이 그대로면 자동으로 비움
- 적용 범위: 휴대·거치 모드 공통

### 구현
`~/clipboard_guard.sh`: `wl-paste --watch`로 클립보드 변경을 감지할 때마다,
그 시점 내용의 해시를 기록해두고 120초 후에도 동일하면 `wl-copy --clear`로
비우는 백그라운드 감시 스크립트. `~/.config/labwc/autostart`에 조건 없이
(양쪽 모드 공통) 추가.

### 검증 상태
파일 반영까지 완료, **실제 복사→120초 후 자동으로 비워지는지는 아직
미검증** — 다음 세션에서 실기기 확인 필요.

## 남은 확인 사항 (다음 세션 최우선)
- [ ] 화면 잠금: 실기기에서 잠금 화면 표시·비밀번호 해제·터치 입력 확인
- [ ] 클립보드 초기화: 실기기에서 2분 후 자동으로 비워지는지 확인
- [ ] (9/25 확인) 이 문서는 원래 9/23 당일 커밋됐어야 했는데 누락되어
  9/25에 뒤늦게 반영함 — devlog 당일 커밋을 계속 놓치는 패턴이 반복되고
  있어, 다음부터는 세션 종료 체크리스트에 "devlog 커밋"을 명시적으로 포함
  할 필요가 있음
