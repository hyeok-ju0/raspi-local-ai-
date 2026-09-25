#!/bin/bash
# 30일 지난 AI 대화 기록 자동 삭제
DELETED=$(find ~/.ai_history/archive -name "*.json" -mtime +30 -print -delete | wc -l)
echo "$(date '+%Y-%m-%d %H:%M:%S') - ${DELETED}개 파일 삭제됨"
