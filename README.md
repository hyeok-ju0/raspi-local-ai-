# raspi-local-ai-
Local AI assistant on Raspberry Pi 5 with private intranet
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
- HDMI 미니 모니터
- UPS HAT
- 블루투스 키보드 (선택, 필수 아님)

### 소프트웨어
- Raspberry Pi OS (64-bit)
- Ollama
- Qwen3 8B / Llama 3.1 8B(gwen3에 문제 발생시)
- Tailscale
- Open WebUI(보류)

## 📋 진행 상황

- [x] 프로젝트 기획 및 부품 결정
- [x] 노트북 사전 테스트 (Ollama + 8B)
- [x] 라즈베리파이 OS 설치
- [ ] 로컬 AI 구동
- [ ] Tailscale 인트라넷 구축
- [ ] 휴대용 핸드헬드 완성
- [ ] 케이스 제작 (3D 모델링)

## 📁 저장소 구조
raspi-local-ai/

├── docs/           # 작업 일지, 트러블슈팅

├── configs/        # 설정 파일

├── scripts/        # 자동화 스크립트

└── hardware/       # 회로도, 부품 리스트

## 📝 진행 기록

매일의 작업 일지와 트러블슈팅은 [`docs/`](./docs) 폴더에 정리합니다.

## 📄 라이선스

MIT License
