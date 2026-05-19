"""Chat store — text + voice-note messages between a parent (user) and a therapist."""
from __future__ import annotations

import json
import secrets
from datetime import datetime
from pathlib import Path
from typing import Optional

DATA_DIR = Path(__file__).resolve().parent.parent / "data"
MESSAGES_FILE = DATA_DIR / "messages.json"
VOICE_DIR = DATA_DIR / "voice_notes"


def _read() -> list[dict]:
    if not MESSAGES_FILE.exists():
        return []
    txt = MESSAGES_FILE.read_text(encoding="utf-8") or ""
    return json.loads(txt) if txt.strip() else []


def _write(messages: list[dict]) -> None:
    MESSAGES_FILE.parent.mkdir(parents=True, exist_ok=True)
    MESSAGES_FILE.write_text(json.dumps(messages, indent=2), encoding="utf-8")


def _thread_id(user_id: str, therapist_id: str) -> str:
    return f"{user_id}__{therapist_id}"


def list_messages(user_id: str, therapist_id: str) -> list[dict]:
    tid = _thread_id(user_id, therapist_id)
    return [m for m in _read() if m["thread_id"] == tid]


def list_threads_for_user(user_id: str) -> list[dict]:
    """Group messages by therapist; return last-message summaries."""
    by_therapist: dict[str, dict] = {}
    for m in _read():
        if m["user_id"] != user_id:
            continue
        tid = m["therapist_id"]
        prev = by_therapist.get(tid)
        if prev is None or m["created_at"] > prev["created_at"]:
            by_therapist[tid] = m
    return sorted(by_therapist.values(), key=lambda m: m["created_at"], reverse=True)


def _next_id() -> str:
    return f"msg_{secrets.token_hex(6)}"


def send_text(user_id: str, therapist_id: str, text: str, sender: str) -> dict:
    messages = _read()
    msg = {
        "message_id": _next_id(),
        "thread_id": _thread_id(user_id, therapist_id),
        "user_id": user_id,
        "therapist_id": therapist_id,
        "sender": sender,
        "kind": "text",
        "text": text,
        "voice_url": None,
        "duration_ms": None,
        "created_at": datetime.now().astimezone().isoformat(timespec="seconds"),
    }
    messages.append(msg)
    _write(messages)
    return msg


def send_voice(user_id: str, therapist_id: str, voice_filename: str,
               duration_ms: int, sender: str) -> dict:
    messages = _read()
    msg = {
        "message_id": _next_id(),
        "thread_id": _thread_id(user_id, therapist_id),
        "user_id": user_id,
        "therapist_id": therapist_id,
        "sender": sender,
        "kind": "voice",
        "text": None,
        "voice_url": f"/api/voice-notes/{voice_filename}",
        "duration_ms": duration_ms,
        "created_at": datetime.now().astimezone().isoformat(timespec="seconds"),
    }
    messages.append(msg)
    _write(messages)
    return msg


def save_voice_file(content: bytes, ext: str = "m4a") -> str:
    VOICE_DIR.mkdir(parents=True, exist_ok=True)
    name = f"{secrets.token_hex(10)}.{ext.lstrip('.')}"
    (VOICE_DIR / name).write_bytes(content)
    return name


def voice_file_path(filename: str) -> Optional[Path]:
    if "/" in filename or ".." in filename:
        return None
    p = VOICE_DIR / filename
    return p if p.exists() else None
