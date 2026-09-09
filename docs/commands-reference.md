# 명령어 참고 (Command Reference)

이 프로젝트에서 쓰는 모든 alias·스크립트를 한 곳에 모았습니다. 늘어날 때마다 이 문서에 추가합니다.

---

## AI 채팅

| 명령어 | 설명 |
|---|---|
| `ai` | 휴대 모드 AI(Qwen3 4B-instruct) 대화형 시작. RAG 꺼진 상태로 시작. 이전 대화 있으면 이어할지 물어봄 |
| `ai-rag` | 휴대 모드 AI, RAG 켜진 상태로 시작 |
| `ai "질문"` | 휴대 모드 AI, 단발성 질문(대화 기록 없이 한 번만 물어봄) |
| `ai new` | 새 대화 시작 (기존 대화는 자동 보관) |
| `ai list` | 보관된 과거 대화 목록 보기 |
| `ai resume <번호>` | 목록에서 고른 과거 대화를 불러와 이어감 |
| `ai-smart "질문"` | 거치 모드 AI(Qwen3 8B). 휴대 모드에서 실행하면 질문을 큐에 저장(전력 부족 대비) |
| `ai-smart-rag` | 거치 모드 AI, RAG 켜진 상태로 대화형 시작 |
| `ai-que` | 휴대 모드에서 쌓인 질문 큐 확인(거치 모드 전환 후 사용) |

### 대화 중 명령어 (`ai`/`ai-smart` 실행 중)
| 입력 | 동작 |
|---|---|
| `rag on` | 이번 대화부터 RAG 검색 켜기 |
| `rag off` | RAG 검색 끄기 (빠른 응답으로 복귀) |
| `rag` 또는 `rag status` | 현재 RAG 상태 확인 |
| `exit` 또는 `quit` | 대화 종료 (정상 종료 시 자동 저장됨) |

---

## RAG 데이터 (암호화)

| 명령어 | 설명 |
|---|---|
| `rag-unlock` | 암호화된 RAG 데이터(`~/.rag_data_encrypted`)를 `~/rag_data`에 마운트(패스프레이즈 입력 필요). **AI에서 RAG를 쓰기 전에 반드시 먼저 실행** |
| `rag-lock` | RAG 데이터 마운트 해제(자리 비울 때, 휴대 모드 전환 전에 권장) |
| `rag-status` | 지금 마운트(잠금 해제) 상태인지 확인 |

### RAG 인덱싱 (새 노트·자료 추가했을 때)
```bash
rag-unlock                                    # 먼저 마운트
python3 ~/rag_data/rag_index.py notes         # 개인노트만 재인덱싱
python3 ~/rag_data/rag_index.py coursework    # 수업자료만 재인덱싱
python3 ~/rag_data/rag_index.py all           # 둘 다 재인덱싱
```
파일을 새로 추가하거나 수정한 뒤에는 위 명령으로 재인덱싱해야 검색에 반영됩니다. 변경 없는 파일은 자동으로 건너뜁니다(증분 처리).

### RAG 검색 테스트 (디버깅용)
```bash
python3 ~/rag_data/rag_search.py "질문 내용" notes        # 개인노트에서만 검색
python3 ~/rag_data/rag_search.py "질문 내용" coursework   # 수업자료에서만 검색
python3 ~/rag_data/rag_search.py "질문 내용" all 5         # 전체에서 top-5개 검색
```

---

## 모델 관리

```bash
ollama ps                          # 지금 메모리에 떠 있는 모델 확인
ollama stop qwen3:4b-instruct      # 특정 모델 강제 언로드
ollama show --template <모델명>     # chat template 확인 (레지스트리 템플릿 고장 여부 점검)
ollama show --parameters <모델명>   # 파라미터·stop 토큰 확인
```

---

## 모니터링 (문제 생겼을 때)

```bash
free -h                            # 메모리 여유 확인
watch -n 1 free -h                 # 실시간 메모리 감시
top                                # CPU 사용률 확인 (%CPU는 코어당 100% 기준, Pi5는 4코어라 최대 400%)
vcgencmd get_throttled             # 저전압/스로틀링 이력 (0x0이면 정상)
dmesg | grep -i "killed process"   # OOM 발생 이력
journalctl -b -1 -p err            # 직전 부팅의 에러 로그 (영구 저널 활성화됨, 2026-08-31~)
```

---

## Syncthing (파일 전송용)

```bash
ls -la ~/Sync/                              # 동기화된 파일 목록 확인
sudo systemctl status syncthing@hyeogju     # 서비스 상태 확인
sudo systemctl restart syncthing@hyeogju    # 서비스 재시작
```
연결이 계속 끊기면(`연결 끊김` 상태) Syncthing 웹 화면(`http://localhost:8384`, 또는 SSH 터널로 원격 접속)에서 `Sync` 폴더 공유를 양쪽에서 껐다 재공유하면 대부분 해결됩니다 (2026-09-07에 겪은 문제, 원인은 폴더 공유 클러스터 설정 불일치).

---

## Git (GitHub 반영)

```bash
cd ~/raspi-local-ai-
git status                         # 뭐가 바뀌었는지 확인
git add <파일명>
git commit -m "설명"
git push
```

---

## 파일 위치 정리

| 경로 | 내용 |
|---|---|
| `~/ai-safe.sh` | 휴대 모드 AI 스크립트 (감시·저장·RAG 토글) |
| `/usr/local/bin/ai-smart-safe` | 거치 모드 AI 스크립트 (전력 확인 + `ai-safe.sh` 호출) |
| `~/.ai_history/current.json` | 진행 중인 대화 |
| `~/.ai_history/archive/*.json` | 보관된 과거 대화들 |
| `~/.rag_data_encrypted/` | 암호화된 RAG 원본 데이터 (평소엔 이 상태) |
| `~/rag_data/` | `rag-unlock` 실행 시에만 나타나는 마운트 지점 (평문처럼 보임) |
| `~/rag_data/notes/`, `~/rag_data/coursework/` | 원본 노트·수업자료 파일 |
| `~/rag_data/index/*.json` | 임베딩 인덱스 |
| `~/raspi-local-ai-/` | GitHub 저장소 로컬 클론 |
