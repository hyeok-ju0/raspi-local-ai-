# 2026-08-31 작업 기록: Qwen3 4B thinking 모드 비활성화 시도 및 트러블슈팅

## 목표
휴대 모드(Qwen3 4B)와 거치 모드(Qwen3 8B) 모두에서 thinking 모드를 확실히 끄는 방법 확보.
지난 세션(8/7, "라즈베리파이 로컬 AI 만들기3")에서 Ollama 네이티브 API(`localhost:11434`)에
`think: false`를 직접 보내는 방식은 성공 사례가 있었으나, 이번엔 RAG를 포함하는
Open WebUI 백엔드 API(`localhost:8080`) 경로에서 동일 방식이 통하는지 검증이 필요했음.

## 1. Open WebUI UI의 think 토글 — 작동 안 함 확인
- 관리자 패널 > 모델 > qwen3:4b > 고급 매개변수에서 "think (Ollama)" 항목을 "기본값" → 끄기로 변경
- 저장 후 실제 채팅(Open WebUI 화면)으로 테스트 → **thinking 과정이 여전히 그대로 노출됨**
  (`<think>` 접힘 UI가 아니라 사고 과정 텍스트가 평문으로 응답에 포함됨)
- 사전 조사에서 확인했던 "Ollama의 think 파라미터가 boolean/string 타입 혼동으로
  오작동한다"는 알려진 버그와 일치하는 것으로 추정
- 참고: `qwen3:8b-nothink`라는 모델이 이미 존재했으나, 이는 과거(8/7) Modelfile에
  `SYSTEM /no_think`를 넣어 시도했다가 실패한 채로 방치된 것으로 확인됨(같은 접근 재실패)

## 2. API 키 발급 — 비관리자 계정 권한 이슈 해결
휴대/거치 모드를 브라우저 대신 터미널+API 방식으로 전환하기 위해 전용 비관리자
계정(`주혁api`)의 API 키가 필요했음.

- 문제: 관리자 패널 > 설정 > 일반에서 "API 키 활성화"를 켜도, `주혁api` 계정의
  설정 > 계정 화면에 API 키 섹션 자체가 나타나지 않음
- 원인: 전역 스위치는 "완전 차단 여부"만 결정하고, 비관리자 계정이 실제로 키를
  생성하려면 **그룹 권한(Admin Panel > Users > Groups > Default Permissions)에
  "API Keys" 기능 권한을 별도로 부여**해야 함. 관리자는 이 권한 체크를 면제받아
  전역 스위치만으로 충분하지만, 일반 사용자는 그렇지 않음
- 해결: 그룹 기본 권한에서 API Keys 권한 활성화 → `주혁api` 계정에 API 키 섹션 노출
  확인 → 키 발급 완료, `~/.owui_api_key`에 `chmod 600`으로 저장
- 부가로 `qwen3:4b` 모델의 접근 제어(비공개)에 `주혁api` 계정이 이미 "읽기"
  권한으로 등록되어 있음을 확인(별도 조치 불필요했음)

## 3. curl + think:false 테스트 중 Pi5 응답 없음 사고
```bash
curl -X POST http://localhost:8080/api/chat/completions \
  -H "Authorization: Bearer $(cat ~/.owui_api_key)" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3:4b",
    "messages": [{"role": "user", "content": "SSH에 대하여 한 문장으로 설명해줘"}],
    "think": false
  }'
```
- 위 명령 실행 후 응답 없이 멈춤 → 몇 분 후 SSH 세션 자체가 끊김
  (`Read from remote host: Connection timed out`, `Broken pipe`)
- 외부(Tailscale)에서도 재접속 불가, 물리적 접근이 어려운 상황이라 자연 복구를 기다림
- **자연 복구됨** (강제 재부팅 없이). 복구 후 확인 결과 파일시스템 손상 없음
  (EXT4 orphan cleanup + 정상 재마운트 패턴, 기존 사고들과 동일)

### 지난 OOM 사고들과의 결정적 차이
- 8/26~28 OOM 사고 때는 `dmesg`에 `Out of memory: Killed process ...` 로그가
  명확히 남아있었음
- **이번엔 OOM 킬러 개입 흔적이 전혀 없음** → 단순 메모리 부족이 아니라 다른
  원인(네트워크/Tailscale 정체, curl 요청이 응답 없이 무한 대기하며 자원을 점유,
  또는 Open WebUI 내부에서 think 파라미터 타입 오류로 인한 행(hang) 등)일 가능성
- **직전 부팅 로그가 이번에도 남아있지 않아**(`no persistent journal was found`)
  정확한 원인을 로그로 확정하지 못함 — 두 번째로 겪는 동일한 한계

## 4. 영구 저널(persistent journal) 활성화
같은 문제(로그 소실로 원인 규명 실패)가 반복되어, 재부팅 후에도 로그가 남도록 조치함.
```bash
sudo mkdir -p /var/log/journal
sudo systemd-tmpfiles --create --prefix /var/log/journal
sudo systemctl restart systemd-journald
```
다음 사고 발생 시 `journalctl -b -1`로 직전 부팅 전체 로그 확인 가능해짐.

## 결론 및 다음 단계
- **`think: false`를 Open WebUI API 경로로 보내는 방식은 현재 원인 불명의 행(hang)을
  유발할 위험이 있어 보류.** 재시도하지 않음
- Ollama 네이티브 API(11434) 직통 방식은 과거 검증된 성공 사례가 있으나, 이 경로는
  RAG(Open WebUI 처리)를 우회하므로 휴대/거치 모드의 RAG 요구사항과 충돌
- 다음 세션에서 조사할 것:
  - 영구 저널이 활성화된 상태에서 문제를 재현해(가능하다면 안전하게 격리된 방식으로)
    실제 원인을 로그로 특정
  - Open WebUI가 아닌 방식(예: 별도 미들웨어/프록시가 요청을 받아 Ollama 네이티브
    API로 think:false 변환 + RAG는 별도로 직접 구현)도 대안으로 검토
  - Open WebUI GitHub 이슈 트래커에서 이 특정 hang 증상이 보고된 사례가 있는지 확인
