#!/bin/bash
# ai-safe.sh - Ollama 직통 호출 + 타임아웃 자동 정리 + 대화 저장/재개/목록
# 단발 모드: ./ai-safe.sh "질문 내용" [모델명]
# 대화형 모드: ./ai-safe.sh
# 새 대화: ./ai-safe.sh new [모델명]
# 목록 보기: ./ai-safe.sh list
# 과거 대화 불러오기: ./ai-safe.sh resume <번호>

HISTORY_DIR="$HOME/.ai_history"
ARCHIVE_DIR="$HISTORY_DIR/archive"
CURRENT_FILE="$HISTORY_DIR/current.json"
mkdir -p "$ARCHIVE_DIR"

MODEL="qwen3:4b-instruct"
SINGLE_PROMPT=""
FORCE_NEW=false
LIST_MODE=false
RESUME_INDEX=""

if [ "$1" = "new" ]; then
  FORCE_NEW=true
  [ -n "$2" ] && MODEL="$2"
elif [ "$1" = "list" ]; then
  LIST_MODE=true
elif [ "$1" = "resume" ]; then
  RESUME_INDEX="$2"
elif [ -n "$1" ] && [[ "$1" != *:* ]]; then
  SINGLE_PROMPT="$1"
  [ -n "$2" ] && MODEL="$2"
elif [ -n "$1" ] && [[ "$1" == *:* ]]; then
  MODEL="$1"
fi

TIMEOUT=240
SYSTEM_PROMPT="2~4문장 정도로 핵심 내용을 충분히 설명하되, 표·이모지·헤더 같은 서식은 쓰지 마세요. 평범한 문장으로만 답하세요. 사용자가 말하지 않은 시간, 이름, 수치 등 세부사항을 지어내지 마세요."

init_fresh_history() {
  python3 -c "
import json, sys
print(json.dumps([{'role': 'system', 'content': sys.argv[1]}]))
" "$SYSTEM_PROMPT" > "$CURRENT_FILE"
}

archive_current() {
  if [ -f "$CURRENT_FILE" ]; then
    local turns
    turns=$(python3 -c "
import json
try:
    h = json.load(open('$CURRENT_FILE', encoding='utf-8', errors='replace'))
    print(len([m for m in h if m['role'] != 'system']))
except: print(0)
")
    if [ "$turns" -gt 0 ]; then
      mv "$CURRENT_FILE" "$ARCHIVE_DIR/$(date +%Y%m%d_%H%M%S).json"
    fi
  fi
}

print_archive_list() {
  python3 -c "
import json, os, glob
files = sorted(glob.glob(os.path.expanduser('$ARCHIVE_DIR/*.json')), reverse=True)
if not files:
    print('보관된 과거 대화가 없습니다.')
for i, f in enumerate(files, 1):
    try:
        h = json.load(open(f, encoding='utf-8', errors='replace'))
        users = [m['content'] for m in h if m['role']=='user']
        last = users[-1][:40] if users else '(내용 없음)'
        n_turns = len(users)
        ts = os.path.basename(f).replace('.json','')
        print(f'{i}. [{ts}] ({n_turns}턴) {last}')
    except Exception as e:
        print(f'{i}. [읽기 오류: {f}]')
"
}

get_archive_file_by_index() {
  python3 -c "
import glob, os, sys
files = sorted(glob.glob(os.path.expanduser('$ARCHIVE_DIR/*.json')), reverse=True)
idx = int(sys.argv[1]) - 1
if 0 <= idx < len(files):
    print(files[idx])
" "$1"
}

if [ "$LIST_MODE" = true ]; then
  echo "[ai] 보관된 대화 목록:"
  print_archive_list
  exit 0
fi

if [ -n "$RESUME_INDEX" ]; then
  TARGET_FILE=$(get_archive_file_by_index "$RESUME_INDEX")
  if [ -z "$TARGET_FILE" ] || [ ! -f "$TARGET_FILE" ]; then
    echo "[ai] 해당 번호의 대화를 찾을 수 없습니다. 'ai list'로 목록을 확인하세요."
    exit 1
  fi
  archive_current
  cp "$TARGET_FILE" "$CURRENT_FILE"
  rm -f "$TARGET_FILE"
  echo "[ai] 대화를 불러왔습니다. 이어서 진행합니다."
  HISTORY_FILE="$CURRENT_FILE"
elif [ -n "$SINGLE_PROMPT" ]; then
  HISTORY_FILE=$(mktemp)
  python3 -c "
import json, sys
print(json.dumps([{'role': 'system', 'content': sys.argv[1]}]))
" "$SYSTEM_PROMPT" > "$HISTORY_FILE"
  trap "rm -f '$HISTORY_FILE'" EXIT
elif [ "$FORCE_NEW" = true ]; then
  archive_current
  init_fresh_history
  HISTORY_FILE="$CURRENT_FILE"
  echo "[ai] 새 대화를 시작합니다."
else
  if [ -f "$CURRENT_FILE" ]; then
    PREV_TURNS=$(python3 -c "
import json
try:
    h = json.load(open('$CURRENT_FILE', encoding='utf-8', errors='replace'))
    print(len([m for m in h if m['role'] != 'system']))
except: print(0)
")
    if [ "$PREV_TURNS" -gt 0 ]; then
      LAST_MSG=$(python3 -c "
import json
h = json.load(open('$CURRENT_FILE', encoding='utf-8', errors='replace'))
users = [m['content'] for m in h if m['role']=='user']
print(users[-1][:40] if users else '')
")
      echo "[ai] 이전 대화가 있습니다 (마지막 질문: \"$LAST_MSG...\")"
      read -r -p "[ai] 이어서 하시겠습니까? (y/n): " RESUME_ANS
      if [ "$RESUME_ANS" != "y" ] && [ "$RESUME_ANS" != "Y" ]; then
        archive_current
        init_fresh_history
      fi
    fi
  else
    init_fresh_history
  fi
  HISTORY_FILE="$CURRENT_FILE"
fi

# 대화 저장용 임시 작업 디렉토리 (매 세션 고유)
WORK_DIR=$(mktemp -d)
trap "rm -rf '$WORK_DIR'" EXIT

call_model() {
  local user_msg="$1"
  echo -n "$user_msg" > "$WORK_DIR/user_msg.txt"

  local REQUEST_BODY
  REQUEST_BODY=$(python3 -c "
import json
history = json.load(open('$HISTORY_FILE', encoding='utf-8', errors='replace'))
user_msg = open('$WORK_DIR/user_msg.txt', encoding='utf-8', errors='replace').read()
history.append({'role': 'user', 'content': user_msg})
body = {
    'model': '$MODEL',
    'messages': history,
    'think': False,
    'stream': True,
    'options': {'num_predict': 500}
}
print(json.dumps(body))
")

  local RESPONSE_TMP="$WORK_DIR/response.txt"
  > "$RESPONSE_TMP"

  curl -s --no-buffer -X POST http://localhost:11434/api/chat \
    -H "Content-Type: application/json" \
    -d "$REQUEST_BODY" 2>/dev/null | while IFS= read -r line; do
      echo "$line" | python3 -c "
import json, sys
try:
    d = json.loads(sys.stdin.buffer.read().decode('utf-8', errors='replace'))
    sys.stdout.buffer.write(d.get('message', {}).get('content', '').encode('utf-8', errors='replace'))
    sys.stdout.flush()
except Exception: pass
" | tee -a "$RESPONSE_TMP"
    done &

  CURL_PID=$!

  ( sleep $TIMEOUT; kill -0 $CURL_PID 2>/dev/null && echo "" && echo "[watchdog] ${TIMEOUT}초 타임아웃" && kill -TERM $CURL_PID 2>/dev/null ) &
  WATCHDOG_PID=$!

  wait $CURL_PID 2>/dev/null
  kill $WATCHDOG_PID 2>/dev/null
  echo ""

  ollama stop "$MODEL" 2>/dev/null

  # 파일을 통해서만 주고받아 인코딩 오류로 인한 저장 실패를 방지
  python3 -c "
import json
history = json.load(open('$HISTORY_FILE', encoding='utf-8', errors='replace'))
user_msg = open('$WORK_DIR/user_msg.txt', encoding='utf-8', errors='replace').read()
assistant_reply = open('$RESPONSE_TMP', encoding='utf-8', errors='replace').read()
history.append({'role': 'user', 'content': user_msg})
history.append({'role': 'assistant', 'content': assistant_reply})
json.dump(history, open('$HISTORY_FILE', 'w', encoding='utf-8'), ensure_ascii=False)
"
  if [ $? -ne 0 ]; then
    echo "[ai] ⚠️ 이번 대화 기록 저장에 실패했습니다 (인코딩 오류). 다음 대화부터는 정상 저장됩니다."
  fi
}

if [ -n "$SINGLE_PROMPT" ]; then
  call_model "$SINGLE_PROMPT"
else
  echo "[ai] $MODEL 대화형 모드 (종료: exit / 새 대화: ai new / 목록: ai list / 불러오기: ai resume N)"
  while true; do
    read -r -p "> " USER_INPUT
    if [ -z "$USER_INPUT" ]; then
      continue
    fi
    if [ "$USER_INPUT" = "exit" ] || [ "$USER_INPUT" = "quit" ]; then
      break
    fi
    call_model "$USER_INPUT"
  done
fi
