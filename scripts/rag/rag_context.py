#!/usr/bin/env python3
"""
rag_context.py - 질문을 받아 관련도 임계값을 넘는 컨텍스트를 JSON으로 반환
사용법: python3 rag_context.py <질문이 담긴 파일 경로>
"""
import sys
import os
import json

sys.path.insert(0, os.path.expanduser("~/rag_data"))
from rag_search import search

THRESHOLD = 0.35
TOP_K = 3

def main():
    query_file = sys.argv[1]
    with open(query_file, encoding="utf-8", errors="replace") as f:
        query = f.read()

    try:
        results = search(query, ["notes", "coursework"], TOP_K)
    except Exception as e:
        print(json.dumps({"used": False, "error": str(e)}))
        return

    qualified = [(score, c) for score, c in results if score >= THRESHOLD]

    if not qualified:
        print(json.dumps({"used": False}))
        return

    context_parts = []
    sources = []
    for score, c in qualified:
        context_parts.append(f"[{c['kb']}/{c['source']}]\n{c['text']}")
        sources.append(f"{c['kb']}/{c['source']} (관련도 {score:.2f})")

    context_text = "\n\n".join(context_parts)
    print(json.dumps({
        "used": True,
        "context": context_text,
        "sources": sources
    }, ensure_ascii=False))

if __name__ == "__main__":
    main()
