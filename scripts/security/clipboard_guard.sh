#!/bin/bash
# 클립보드 자동 초기화 - 복사 후 120초 지나도 그대로면 비움
export WAYLAND_DISPLAY=wayland-0
export XDG_RUNTIME_DIR=/run/user/1000

wl-paste --watch bash -c '
  CURRENT=$(wl-paste 2>/dev/null | sha256sum)
  (
    sleep 120
    AFTER=$(wl-paste 2>/dev/null | sha256sum)
    if [ "$CURRENT" = "$AFTER" ]; then
      wl-copy --clear 2>/dev/null
    fi
  ) &
'
