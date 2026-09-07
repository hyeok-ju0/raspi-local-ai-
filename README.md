# Raspberry Pi 5 Local AI Assistant

> 개인정보 보호를 위한 오프라인 로컬 AI 비서 및 개인 인트라넷 구축 프로젝트

## 📌 개요

라즈베리파이 5에 로컬 LLM을 직접 구동하고, Tailscale 기반 인트라넷으로
다중 기기 간 안전한 데이터 흐름을 구축하는 임베디드 AI 프로젝트입니다.
휴대 모드(배터리)와 거치 모드(외부 전원)를 전원 종류로 자동 판별해,
"기본은 차단, 의도적으로만 연결"이라는 원칙 아래 동작합니다.

## 🎯 동기

- 클라우드 AI 서비스 사용 시 개인정보가 외부 서버로 전송되는 문제
- 메신저 기반 파일 공유 시 데이터 유출 우려
- "내 데이터는 내 기기 안에서만 처리되어야 한다"는 원칙

## 🧭 정체성 (2026-08 재정립)

중간발표에서 "기성품 조합에 불과함", "모델 선정 이유 불명확"이라는 지적을 받고
소프트웨어 계층을 전면 재검토했습니다.

- **AI 역할**: 범용 채팅형 비서 단일 역할 (초기에 검토했던 "프라이버시 감시자"
  AI 기능은 로컬 AI의 핵심 가치와 논리적으로 충돌하여 폐기 — 자세한 이유는
  [`docs/2026-08-ai-layer-redesign.md`](./docs/2026-08-ai-layer-redesign.md) 참고)
- **보안은 AI가 아닌 하드웨어·비-AI 소프트웨어가 담당**: 킬 스위치, 전원 기반
  모드 감지, RAG 폴더 암호화, 화면 잠금 등 12개 소프트웨어 기능으로 위협 대응
- **차별점**: 노트북에서도 재현 가능한 "AI 스택 조합"이 아니라, 전력 감지·
  배터리 보호 회로·킬 스위치 등 **하드웨어와 밀접하게 결합된 설계**를 강조

## 🛠 기술 스택

### 하드웨어
- Raspberry Pi 5 8GB + 공식 액티브 쿨러
- Waveshare DSI 3.5인치 터치스크린 (800×480, 정전식)
- 배터리 플랜 A: LiPo 605080 + FM5324HJ1 자체 배선 (CC1/CC2 5.1kΩ 풀다운), 스로틀 실측 `0x0` 유지로 99% 확정
- 전원 종류 기반 모드 자동 판별 (`/proc/device-tree/chosen/power/max_current`: 0xbb8=3A=휴대, 0x1388=5A=거치)

### 소프트웨어
- OS: Debian 13 Trixie, Wayland/labwc
- Ollama + **Qwen3 4B**(휴대 모드, 전환 진행 중) / **Qwen3 8B**(거치 모드)
  - 이전에는 Gemma 4 E2B(휴대)를 사용했으나, 텍스트 전용 사용에도 vision/audio
    capability를 상시 점유해 반복 OOM이 발생 → 텍스트 전용 모델로 교체
    (자세한 트러블슈팅: [`docs/2026-08-ai-layer-redesign.md`](./docs/2026-08-ai-layer-redesign.md))
- Open WebUI (Docker, `OFFLINE_MODE=true`) — 거치 모드 화면 인터페이스, RAG 지식베이스 관리
- 휴대 모드는 브라우저 대신 **터미널 + Open WebUI API 직접 호출** 방식으로 전환 중
  (브라우저 자체가 메모리 문제의 핵심 원인으로 확인됨)
- RAG: nomic-embed-text-v2 임베딩, 수업자료/개인노트 KB 분리, 1시간 간격 증분 동기화
- Tailscale (인트라넷), Syncthing (파일 동기화)
- 한국어 입력: fcitx5 + fcitx5-hangul + squeekboard
- gocryptfs 기반 RAG 폴더 암호화 (설계 완료, 구현 예정)

## 📋 진행 상황

### 완료
- [x] 하드웨어 조립 (Pi5 + 터치스크린 + 배터리 플랜 A)
- [x] 전원 기반 모드 자동 판별 (`detect-power-mode` systemd 서비스)
- [x] 부팅 시 무선 자동 제어 (휴대=차단, 거치=허용)
- [x] 스마트 큐잉(`ai-que`), rfkill 킬 스위치(`killon`/`killoff`)
- [x] Tailscale 인트라넷, SSH 키 인증, Syncthing
- [x] Open WebUI 설치 및 부팅 자동 실행
- [x] 한국어 입력 (fcitx5 + squeekboard)
- [x] AI 정체성 재정립 (단일 채팅 비서 역할, 감시자 기능 폐기)
- [x] 보안·기능 소프트웨어 12개 설계 확정 (구현은 진행 중)
- [x] RAG 설계 확정 (임베딩 모델, KB 구조, 동기화 방식)
- [x] 모델 재선정 (Gemma 4 E2B → Qwen3 4B)

### 진행 중
- [ ] Qwen3 4B thinking 모드 비활성화 (Open WebUI UI 토글 작동 안 함 확인, API 경유 방식은 원인 불명 hang 사고로 보류)
- [ ] 휴대 모드 터미널+API 래퍼 스크립트
- [ ] RAG 동기화 systemd 유닛, Modelfile stop 토큰 검증
- [ ] 보안·기능 소프트웨어 12개 실제 구현
- [ ] 케이스 설계 (Fusion 360)

## 📁 저장소 구조
```
raspi-local-ai/
├── docs/           # 작업 일지, 설계 문서, 트러블슈팅
├── configs/        # 설정 파일, 환경 구성 가이드, Modelfile
├── scripts/        # 자동화 스크립트
└── hardware/       # 회로도, 부품 리스트
```

## 📝 진행 기록

- 일별 작업 일지: [`docs/devlog.md`](./docs/devlog.md)
- 초기 설계 배경: [`docs/design-concept.md`](./docs/design-concept.md)
- 차별화 포인트: [`docs/프로젝트_차별화_컨셉.md`](./docs/프로젝트_차별화_컨셉.md)
- AI/소프트웨어 계층 재설계 전체 기록(2026-08): [`docs/2026-08-ai-layer-redesign.md`](./docs/2026-08-ai-layer-redesign.md)
- thinking 모드 트러블슈팅(2026-08-31): [`docs/2026-08-31-thinking-mode-troubleshooting.md`](./docs/2026-08-31-thinking-mode-troubleshooting.md)

> ⚠️ `design-concept.md`와 `프로젝트_차별화_컨셉.md`는 프로젝트 초기(2026년 6월) 설계
> 배경을 담은 문서입니다. 이후 변경된 내용은 문서 내 "2026-08 갱신" 표시가 있는
> 섹션과 위 재설계 문서를 우선 참고해 주세요.

## 📄 라이선스

MIT License
