# 개발 일지

---

## 2026-06-17 (1일차) - 프로젝트 시작

### 한 일
- 프로젝트 기획 확정 (로컬 AI + 인트라넷 + 핸드헬드)
- 부품 결정 및 디바이스마트 주문
- GitHub 저장소 생성
- 노션 작업 일지 세팅
- 노트북에 Ollama + Qwen3 8B 설치 및 테스트

### 주요 결정
- 본체: 라즈베리파이 5 8GB 정품 선택
- 액세서리: 디바이스마트 묶음 구매 (가성비 우선)
- 모델: Qwen3 8B 우선, 3B 병행 운영 예정

---

## 2026-06-18 (2일차) - README 정리 및 차별화 컨셉 업로드

### 한 일
- README.md 갱신 (블루투스 키보드 "선택, 필수 아님" 명시, 노트북 사전 테스트 체크 완료로 갱신)
- 차별화 컨셉 문서 업로드 (GitHub `docs/프로젝트_차별화_컨셉.md` 신규 생성, Notion에도 동일 페이지 신규 생성)

### 주요 결정
- 프로젝트 차별화 방향: Cyberdeck → Privacy-First Pocket Server (프라이버시 / AI 중심 제어 / 듀얼 모드 3축 정체성)
- 소형화 목표: 스마트폰 크기(약 85×56mm) 지향 (이후 06-19에 "주머니 사이즈"로 재조정)
- 배터리 폼팩터 확정: 리튬폴리머 직결 (UPS HAT 제외)
- 케이스 두께 기준: 액티브 쿨러 높이 측정 후 설정 완료
- 디스플레이 방식·적층 구조는 미확정 상태로 다음 날(06-19) 확정

---

## 2026-06-19 (3일차) - 라즈베리파이 설치 완료 및 컨셉 업데이트

### 한 일
- 라즈베리파이 OS 설치, SSH 접속 완료
- Ollama + Qwen3 8B 설치 완료
- 전체 설계 컨셉 정교화
- 인트라넷 정체성 재정의 (서버 → 자료 이동 통로)
- 적층 구조 확정 (디스플레이-배터리-보드-쿨러, 약 42mm)
- 디스플레이 확정 (DSI 3.5인치 터치스크린)
- 배터리 확정 (LiPo 2000mAh + IP5306)

### 주요 결정
- 케이스 없이 1차 완성 (방열 최적 + 빠른 동작 확인)
- 3B 기본 + 8B 필요시 수동 전환 전략
- Open WebUI 풀스크린 부팅 자동 실행

---

## 2026-06-20 (4일차) - 인트라넷 + 로컬 AI 환경 완성

### 한 일
- 성능 실측 (Qwen3 8B)
- Tailscale 설치 및 인트라넷 구성
- Docker 설치
- Open WebUI 설치 및 Ollama 연결
- 폰 Tailscale 설치 + Open WebUI 접속 확인

### 성능 실측 결과
| 테스트 | eval rate | 온도 |
|---|---|---|
| 짧은 질문 | 2.26~2.29 tokens/s | 60도 |
| 중간 질문 | 2.22 tokens/s | 60도 |
| 긴 질문 | 2.10 tokens/s | 64.2도 |

RAM 점유: 8B 모델 6.3GB / 7.9GB → 3B 기본 운영 전략 확정

### 트러블슈팅
- Qwen3 8B Thinking 모드 끄기 실패 (`/no_think`, `/set parameter think false` 무효)
- Open WebUI Ollama URL 수정 필요 (`host.docker.internal` → `localhost`)

### 현재 네트워크 구성
```
폰 + 노트북 (Tailscale)
        ↓
Tailscale 인트라넷 (100.103.109.7)
        ↓
라즈베리파이 5
├── Ollama (Qwen3 8B)
└── Open WebUI (:8080)
```

---

## 2026-06-21 (5일차) - 1차 필수 항목 전체 완료

### 한 일
- 태블릿(Galaxy Tab S11) Tailscale 설치 및 라즈베리파이 연결 확인
- Llama 3.2 3B 설치 (`ollama pull llama3.2:3b`)
- `~/.bashrc`에 alias 등록 (`ai` → Llama 3.2 3B, `ai-smart` → Qwen3 8B)
- SSH 키 인증 설정 (ed25519 키 생성, `authorized_keys` 등록)
- 부팅 시 Open WebUI 자동 실행 설정 (systemd + Docker 재시작 정책)
- Syncthing 파일 동기화 설치 및 설정 (라즈베리파이 + 노트북, 외부 릴레이/전역 발견 비활성화)
- 1차 필수 항목 10개 전체 완료 ✅

### 주요 결정
- Llama 3.2 3B 한국어 입력 시 다국어 혼용 확인 → 한국어 작업 시 영어 입력 권장
- alias 용도 분리: `ai`(일상/간단, 빠름) vs `ai-smart`(복잡한 추론·한국어)
- Syncthing 외부 노출 최소화: `relaysEnabled`/`globalAnnounceEnabled` 모두 false, NAT 통과 비활성화

### 트러블슈팅
- Llama 3.2 3B 한국어 입력 시 다국어 혼용 → 영어 입력으로 우회 확인

### 다음에 할 일
- [ ] 거치 서버 모드 (이더넷 트리거 자동 전환)
- [ ] DSI 터치스크린 + LiPo 배터리 하드웨어 통합
- [ ] RGB LED 장착 (GPIO 연동)
- [ ] 킬 스위치 1차 (rfkill + GPIO)
- [ ] 3D 프린팅 케이스 (Fusion 360)
