#!/usr/bin/env python3
"""
rag_index.py - notes/coursework 폴더를 스캔해서 청크 + 임베딩 생성
사용법: python3 rag_index.py [notes|coursework|all]
"""
import os
import sys
import json
import hashlib
import glob
import urllib.request

RAG_ROOT = os.path.expanduser("~/rag_data")
EMBED_MODEL = "nomic-embed-text-v2-moe"
OLLAMA_URL = "http://localhost:11434/api/embeddings"
CHUNK_SIZE = 400
CHUNK_OVERLAP = 50

def get_embedding(text):
    data = json.dumps({"model": EMBED_MODEL, "prompt": text}).encode("utf-8")
    req = urllib.request.Request(OLLAMA_URL, data=data, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as resp:
        result = json.loads(resp.read().decode("utf-8"))
    return result["embedding"]

def extract_text(filepath):
    ext = os.path.splitext(filepath)[1].lower()
    if ext in (".md", ".txt"):
        with open(filepath, encoding="utf-8", errors="replace") as f:
            return f.read()
    elif ext == ".pdf":
        try:
            from pypdf import PdfReader
            reader = PdfReader(filepath)
            return "\n".join(page.extract_text() or "" for page in reader.pages)
        except Exception as e:
            print(f"  ⚠️ PDF 추출 실패: {filepath} ({e})")
            return ""
    return ""

def chunk_text(text, size=CHUNK_SIZE, overlap=CHUNK_OVERLAP):
    text = text.strip()
    if not text:
        return []
    chunks = []
    start = 0
    while start < len(text):
        end = start + size
        chunks.append(text[start:end])
        if end >= len(text):
            break
        start = end - overlap
    return chunks

def file_hash(filepath):
    h = hashlib.sha256()
    with open(filepath, "rb") as f:
        h.update(f.read())
    return h.hexdigest()

def index_folder(kb_name):
    folder = os.path.join(RAG_ROOT, kb_name)
    index_path = os.path.join(RAG_ROOT, "index", f"{kb_name}.json")

    # 기존 인덱스 로드 (증분 처리를 위해)
    existing = {}
    if os.path.exists(index_path):
        with open(index_path, encoding="utf-8") as f:
            existing_data = json.load(f)
            for entry in existing_data:
                existing.setdefault(entry["source"], {"hash": entry.get("file_hash"), "chunks": []})
                existing[entry["source"]]["chunks"].append(entry)

    files = []
    for ext in ("*.md", "*.txt", "*.pdf"):
        files.extend(glob.glob(os.path.join(folder, "**", ext), recursive=True))

    new_index = []
    unchanged_count = 0
    updated_count = 0

    current_sources = set()
    for filepath in files:
        rel_source = os.path.relpath(filepath, folder)
        current_sources.add(rel_source)
        h = file_hash(filepath)

        if rel_source in existing and existing[rel_source]["hash"] == h:
            # 변경 없음 - 기존 청크 재사용
            new_index.extend(existing[rel_source]["chunks"])
            unchanged_count += 1
            continue

        # 새 파일이거나 변경됨 - 재처리
        text = extract_text(filepath)
        chunks = chunk_text(text)
        if not chunks:
            print(f"  ⚠️ 텍스트 없음, 건너뜀: {rel_source}")
            continue

        print(f"  처리 중: {rel_source} ({len(chunks)}개 청크)")
        for i, chunk in enumerate(chunks):
            try:
                emb = get_embedding(chunk)
            except Exception as e:
                print(f"    ⚠️ 임베딩 실패 (청크 {i}): {e}")
                continue
            new_index.append({
                "source": rel_source,
                "file_hash": h,
                "chunk_id": i,
                "text": chunk,
                "embedding": emb
            })
        updated_count += 1

    # 삭제된 파일 처리 (더 이상 존재하지 않는 파일의 청크는 자동으로 new_index에서 빠짐)
    removed = set(existing.keys()) - current_sources
    if removed:
        print(f"  삭제된 파일 {len(removed)}개 인덱스에서 제외: {', '.join(removed)}")

    os.makedirs(os.path.dirname(index_path), exist_ok=True)
    with open(index_path, "w", encoding="utf-8") as f:
        json.dump(new_index, f, ensure_ascii=False)

    print(f"[{kb_name}] 완료: 변경없음 {unchanged_count}개 파일, 갱신 {updated_count}개 파일, 총 {len(new_index)}개 청크")

if __name__ == "__main__":
    target = sys.argv[1] if len(sys.argv) > 1 else "all"
    targets = ["notes", "coursework"] if target == "all" else [target]
    for kb in targets:
        print(f"=== {kb} 인덱싱 시작 ===")
        index_folder(kb)
