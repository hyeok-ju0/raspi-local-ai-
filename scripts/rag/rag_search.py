#!/usr/bin/env python3
"""
rag_search.py - 저장된 인덱스에서 질문과 가장 관련된 청크 검색
사용법: python3 rag_search.py "질문 내용" [notes|coursework|all] [top_k]
"""
import os
import sys
import json
import math
import urllib.request

RAG_ROOT = os.path.expanduser("~/rag_data")
EMBED_MODEL = "nomic-embed-text-v2-moe"
OLLAMA_URL = "http://localhost:11434/api/embeddings"

def get_embedding(text):
    data = json.dumps({"model": EMBED_MODEL, "prompt": text}).encode("utf-8")
    req = urllib.request.Request(OLLAMA_URL, data=data, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as resp:
        result = json.loads(resp.read().decode("utf-8"))
    return result["embedding"]

def cosine_similarity(a, b):
    dot = sum(x * y for x, y in zip(a, b))
    norm_a = math.sqrt(sum(x * x for x in a))
    norm_b = math.sqrt(sum(x * x for x in b))
    if norm_a == 0 or norm_b == 0:
        return 0
    return dot / (norm_a * norm_b)

def load_index(kb_name):
    path = os.path.join(RAG_ROOT, "index", f"{kb_name}.json")
    if not os.path.exists(path):
        return []
    with open(path, encoding="utf-8") as f:
        return json.load(f)

def search(query, kb_names, top_k=3):
    query_emb = get_embedding(query)
    all_chunks = []
    for kb in kb_names:
        chunks = load_index(kb)
        for c in chunks:
            c["kb"] = kb
            all_chunks.append(c)

    if not all_chunks:
        return []

    scored = []
    for c in all_chunks:
        score = cosine_similarity(query_emb, c["embedding"])
        scored.append((score, c))

    scored.sort(key=lambda x: x[0], reverse=True)
    return scored[:top_k]

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("사용법: python3 rag_search.py \"질문\" [notes|coursework|all] [top_k]")
        sys.exit(1)
    query = sys.argv[1]
    kb_target = sys.argv[2] if len(sys.argv) > 2 else "all"
    top_k = int(sys.argv[3]) if len(sys.argv) > 3 else 3
    kb_names = ["notes", "coursework"] if kb_target == "all" else [kb_target]

    results = search(query, kb_names, top_k)
    if not results:
        print("검색 결과 없음 (인덱스가 비어있거나 파일이 없습니다)")
    for score, c in results:
        print(f"[{c['kb']}/{c['source']}] 유사도={score:.3f}")
        print(f"  {c['text'][:100]}...")
        print()
