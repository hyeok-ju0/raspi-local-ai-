# docs/devlog.md
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
