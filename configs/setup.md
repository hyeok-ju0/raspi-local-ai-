# configs/setup.md
# 환경 설정 가이드 (2026-08 갱신)

## 네트워크 정보
- 라즈베리파이 로컬 IP: `192.168.0.216` (DHCP, 변동 가능)
- 라즈베리파이 Tailscale IP: `100.103.109.7`

---

## Ollama 설치
```bash
curl -fsSL https://ollama.com/install.sh | sh
```

### 모델 설치
```bash
# 휴대 모드 (텍스트 전용, 128K 컨텍스트)
ollama pull qwen3:4b

# 거치 모드 (복잡한 추론용)
ollama pull qwen3:8b
```

> ⚠️ **모델 변경 이력**: 처음에는 `llama3.2:3b`(휴대)/`qwen3:8b`(거치) 조합을
> 썼다가, 이후 `gemma4:e2b`(휴대)로 교체했으나 vision/audio capability로 인한
> 반복 OOM 문제가 발견되어 다시 `qwen3:4b`(텍스트 전용)로 교체했습니다.
> 자세한 경위는 `docs/2026-08-ai-layer-redesign.md` 참고.

### 모델 alias 설정 (`~/.bashrc`)
```bash
alias ai='ollama run qwen3:4b'         # 전환 진행 중 (기존 gemma4:e2b)
alias ai-smart='/usr/local/bin/ai-smart-safe'   # 전력 상태 확인 후 qwen3:8b 실행
```

### Modelfile 기반 커스텀 모델 (시스템 프롬프트·파라미터 적용)
`configs/Modelfile.ai`(휴대), `configs/Modelfile.ai-smart`(거치)에 시스템
프롬프트와 파라미터(num_ctx, temperature 등)가 정의되어 있습니다.

```bash
ollama create ai -f configs/Modelfile.ai
ollama create ai-smart -f configs/Modelfile.ai-smart
```

> ⚠️ Ollama 레지스트리의 chat template이 고장나 있는 경우가 있었습니다
> (Gemma 4 E2B에서 `{{ .Prompt }}` 한 줄만 반환되는 사례 발견). 새 모델로
> 빌드한 뒤에는 반드시 아래로 실제 템플릿과 stop 토큰을 검증하세요.
> ```bash
> ollama show --template ai
> ollama show --parameters ai
> ```

### thinking 모드 비활성화 (미해결)
- Modelfile의 `PARAMETER think false`는 Ollama 공식 미지원 파라미터(오류 발생)
- CLI `--think=false`도 Qwen3 계열에서 버그 보고 다수
- Open WebUI 관리자 패널의 모델별 "think (Ollama)" 토글도 작동하지 않음 확인(2026-08-31)
- curl로 Open WebUI API에 `"think": false`를 직접 보내는 방식은 원인 불명의
  Pi5 응답없음 사고를 유발해 현재 **보류 상태** (`docs/2026-08-31-thinking-mode-troubleshooting.md` 참고)

---

## Tailscale 설치
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

> ⚠️ 초기에는 "자료 전송 시 수동으로 켜고 끄기(`tailscale up`/`down`)"
> 방식을 계획했으나, 이후 **전원 종류 기반 자동 제어**로 대체되었습니다.
> `detect-power-mode` systemd 서비스가 부팅 시 전원 종류(3A=휴대/5A=거치)를
> 판별해 무선(Wi-Fi·블루투스)을 자동으로 차단/허용합니다. 수동 제어가
> 필요하면 `killon`(차단)/`killoff`(허용) 명령을 사용하세요.

---

## Docker 설치
```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# 재로그인 필요
```

---

## Open WebUI 설치
실제 운영 중인 컨테이너는 Docker named volume(`open-webui:/app/backend/data`)을
사용하며, 호스트 폴더를 bind mount하지 않습니다. `NetworkMode=host`라
`localhost:11434`(Ollama), `localhost:8080`(Open WebUI 자체)로 서로 통신합니다.

```bash
docker run -d \
  --network=host \
  -v open-webui:/app/backend/data \
  --name open-webui \
  --restart always \
  -e OFFLINE_MODE=true \
  -e SCARF_NO_ANALYTICS=true \
  -e DO_NOT_TRACK=true \
  -e ANONYMIZED_TELEMETRY=false \
  -e WEBUI_SECRET_KEY=<고정값> \
  -e RAG_EMBEDDING_MODEL=nomic-embed-text-v2 \
  ghcr.io/open-webui/open-webui:main
```

> ⚠️ `RAG_EMBEDDING_MODEL`은 설계상 `nomic-embed-text-v2`로 확정했으나,
> 2026-08-28 시점 실제 컨테이너 환경변수는 아직 이전 기본값
> (`sentence-transformers/all-MiniLM-L6-v2`)이었습니다. 재배포 시 위 값으로
> 갱신이 필요합니다.

### 접속 주소
- 로컬: `http://192.168.0.216:8080`
- Tailscale: `http://100.103.109.7:8080`

### API 키 발급 (터미널+API 방식용)
휴대 모드는 브라우저 대신 터미널에서 Open WebUI API를 직접 호출하는 방식으로
전환 중입니다. 전용 비관리자 계정(`주혁api`)의 API 키가 필요합니다.

1. 관리자 패널 > 설정 > 일반 > "API 키 활성화" 켜기
2. 관리자 패널 > 사용자 > 그룹 > 기본 권한에서 **"API Keys" 권한을 별도로 활성화**
   (전역 스위치만으로는 비관리자 계정에 API 키 메뉴가 노출되지 않음)
3. 대상 계정으로 로그인 > 설정 > 계정 > API 키 생성
4. 발급받은 키는 안전하게 보관
   ```bash
   nano ~/.owui_api_key   # sk-로 시작하는 값 저장
   chmod 600 ~/.owui_api_key
   ```

### RAG 지식베이스 API 사용 예시
```bash
curl -X POST http://localhost:8080/api/chat/completions \
  -H "Authorization: Bearer $(cat ~/.owui_api_key)" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3:4b",
    "messages": [{"role": "user", "content": "질문 내용"}],
    "files": [{"type": "collection", "id": "개인노트-KB-id"}]
  }'
```
> ⚠️ 위 요청에 `"think": false`를 추가로 넣는 조합은 2026-08-31에 원인 불명의
> Pi5 응답없음 사고를 일으켜 현재 보류 중입니다. 재시도 전 반드시
> `docs/2026-08-31-thinking-mode-troubleshooting.md` 확인.

---

## 부팅 자동 실행 (거치 모드, 적용 완료)
```bash
# /etc/xdg/autostart/openwebui.desktop
[Desktop Entry]
Type=Application
Name=OpenWebUI
Exec=chromium-browser --kiosk --app=http://localhost:8080
```
> 휴대 모드는 위 브라우저 자동 실행에서 제외하는 방향으로 전환 중입니다
> (브라우저가 반복 OOM의 결정적 원인으로 확인됨).

---

## 절전 설정
```bash
# 화면 2분 후 자동 꺼짐
xset s 120
xset +dpms

# CPU 절전 모드
echo "powersave" | sudo tee /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
```

---

## 온도·메모리·전력 모니터링
```bash
# 현재 온도 확인
vcgencmd measure_temp

# 실시간 모니터링 (2초마다)
watch -n 2 vcgencmd measure_temp

# 저전압/스로틀링 이력 확인 (0x0이면 정상)
vcgencmd get_throttled

# 메모리 여유 실시간 확인 (모델 실행 테스트 시 필수)
watch -n 1 free -h

# OOM 발생 이력 확인
dmesg | grep -i "killed process"
```

---

## 영구 저널 활성화 (2026-08-31 적용)
기본 상태에서는 재부팅 시 이전 부팅의 로그가 사라져, OOM 등 사고 원인 규명이
반복적으로 어려웠습니다. 아래 설정으로 재부팅 후에도 `journalctl -b -1`로
직전 부팅 로그를 확인할 수 있습니다.
```bash
sudo mkdir -p /var/log/journal
sudo systemd-tmpfiles --create --prefix /var/log/journal
sudo systemctl restart systemd-journald
```

---

## 알려진 위험 / 주의사항
- **동시 실행 금지**: 두 모델을 동시에 실행하면 RAM 초과로 시스템이 멈추거나
  SSH 연결이 끊길 수 있습니다. 모델 전환 시 `ollama stop <모델명>`으로 이전
  모델을 먼저 종료하세요.
- **num_ctx를 무작정 높이지 말 것**: 32768 설정에서 반복적으로 OOM이
  발생했습니다(6.6GB+ 사용). 16384부터 시작해 실측 후 조정하세요.
- **Pi5 자체 화면에서 개발 작업(브라우저 등)을 하면서 동시에 모델을
  테스트하지 말 것**: 실제 킥오스크 배포 조건과 다른 무거운 환경이 되어
  결과가 왜곡됩니다. 모델 테스트는 노트북 등 별도 기기에서 Tailscale로
  접속하거나, 최소한 Pi5의 브라우저를 완전히 종료(`pkill -9 chromium`)한
  상태에서 진행하세요.
- **모드 전환 시 전원 동시 연결 금지**: 배터리와 5A 어댑터가 동시에
  연결되면 저전압 경고와 강제 재부팅이 발생합니다. 전원을 완전히 뽑은
  후에만 모드를 전환하세요.
