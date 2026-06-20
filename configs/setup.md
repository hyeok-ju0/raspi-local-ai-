# configs/setup.md
# 환경 설정 가이드

## 네트워크 정보
- 라즈베리파이 로컬 IP: `192.168.0.216`
- 라즈베리파이 Tailscale IP: `100.103.109.7`

---

## Ollama 설치
```bash
curl -fsSL https://ollama.com/install.sh | sh
```

### 모델 설치
```bash
# 기본 모델 (3B, 일상 작업용)
ollama pull llama3.2:3b

# 고급 모델 (8B, 복잡한 추론용)
ollama pull qwen3:8b
```

### 모델 alias 설정 (~/.bashrc)
```bash
alias ai='ollama run llama3.2:3b'
alias ai-smart='ollama run qwen3:8b'
```

---

## Tailscale 설치
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

### 휴대 모드 (수동 제어)
```bash
sudo tailscale up    # 자료 전송 시 켜기
sudo tailscale down  # 전송 후 끄기
```

---

## Docker 설치
```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# 재로그인 필요
```

---

## Open WebUI 설치
```bash
docker run -d \
  --network=host \
  -v open-webui:/app/backend/data \
  --name open-webui \
  --restart always \
  ghcr.io/open-webui/open-webui:main
```

### 접속 주소
- 로컬: `http://192.168.0.216:8080`
- Tailscale: `http://100.103.109.7:8080`

### 설정 변경 사항
- Ollama API URL: `http://localhost:11434` (기본값 수정 필요)
- OpenAI API: **비활성화** (외부 전송 차단)

---

## 부팅 자동 실행 설정 (예정)
```bash
# /etc/xdg/autostart/openwebui.desktop
[Desktop Entry]
Type=Application
Name=OpenWebUI
Exec=chromium-browser --start-fullscreen --app=http://localhost:8080
```

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

## 온도 모니터링
```bash
# 현재 온도 확인
vcgencmd measure_temp

# 실시간 모니터링 (2초마다)
watch -n 2 vcgencmd measure_temp
```
