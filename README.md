# Raspberry Pi 5 Local AI Assistant

> 개인정보 보호를 위한 오프라인 로컬 AI 비서 및 개인 인트라넷 구축 프로젝트

## 📌 개요

라즈베리파이 5에 로컬 LLM을 직접 구동하고, Tailscale 기반 인트라넷으로
다중 기기 간 안전한 데이터 흐름을 구축하는 임베디드 AI 프로젝트입니다.

## 🎯 동기

- 클라우드 AI 서비스 사용 시 개인정보가 외부 서버로 전송되는 문제
- 메신저 기반 파일 공유 시 데이터 유출 우려
- "내 데이터는 내 기기 안에서만 처리되어야 한다"는 원칙

## 🛠 기술 스택

### 하드웨어
- Raspberry Pi 5 (8GB RAM)
- DSI 3.5인치 터치스크린
- LiPo 3000mAh 배터리 (IP5305T 충방전 모듈)
- 블루투스 키보드 (선택, 필수 아님)

### 소프트웨어
- Raspberry Pi OS (64-bit)
- Ollama
- Qwen3 8B (복잡한 추론용) + Llama 3.2 3B (기본/일상용, 듀얼 모델 운영)
- Tailscale
- Open WebUI
- Syncthing (파일 동기화)

## 📋 진행 상황

- [x] OS 설치 + SSH 접속
- [x] Ollama + Qwen3 8B 설치
- [x] 성능 실측
- [x] Tailscale 인트라넷 구성
- [x] Open WebUI 설치 및 연결
- [x] 노트북 + 폰 + 태블릿 인트라넷 연결
- [x] Llama 3.2 3B 설치
- [x] SSH 키 인증
- [x] Syncthing 파일 동기화
- [x] 부팅 시 Open WebUI 자동 실행
- [ ] DSI 터치스크린 + LiPo 배터리 통합 (부품 구매 완료, 조립 대기)

## 📁 저장소 구조
raspi-local-ai/

├── docs/           # 작업 일지, 트러블슈팅

├── configs/        # 설정 파일

├── scripts/        # 자동화 스크립트

└── hardware/       # 회로도, 부품 리스트

## 📝 진행 기록

매일의 작업 일지와 트러블슈팅은 [`docs/devlog.md`](./docs/devlog.md)에 정리합니다.
설계 배경은 [`docs/design-concept.md`](./docs/design-concept.md), 차별화 포인트는 [`docs/프로젝트_차별화_컨셉.md`](./docs/프로젝트_차별화_컨셉.md)에서 확인할 수 있습니다.

## 📄 라이선스

MIT License
