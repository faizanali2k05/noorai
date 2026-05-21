"""Chat store — text + voice-note messages between a parent (user) and a therapist.

Messages persist via the shared store (``utils.db``). Voice-note audio is binary
and lives in **Google Cloud Storage** when ``NOORAI_VOICE_BUCKET`` is set
(required in production — Cloud Run's local disk is ephemeral); otherwise it
falls back to a local ``data/voice_notes`` directory for development.
"""
from __future__ import annotations

import os
import re
import secrets
from datetime import datetime
from pathlib import Path
from typing import Optional

from utils import db

VOICE_DIR = Path(__file__).resolve().parent.parent / "data" / "voice_notes"
VOICE_BUCKET = os.environ.get("NOORAI_VOICE_BUCKET", "").strip()
_SAFE_NAME = re.compile(r"^[A-Za-z0-9_.-]+$")


def _now() -> str:
    return datetime.now().astimezone().isoformat(timespec="seconds")


def _thread_id(user_id: str, therapist_id: str) -> str:
    return f"{user_id}__{therapist_id}"


def list_messages(user_id: str, therapist_id: str) -> list[dict]:
    tid = _thread_id(user_id, therapist_id)
    msgs = [m for m in db.messages.where("thread_id", tid)]
    msgs.sort(key=lambda m: m.get("created_at", ""))
    return msgs


def list_threads_for_user(user_id: str) -> list[dict]:
    """Group a user's messages by therapist; return the latest per thread."""
    by_therapist: dict[str, dict] = {}
    for m in db.messages.where("user_id", user_id):
        tid = m["therapist_id"]
        prev = by_therapist.get(tid)
        if prev is None or m.get("created_at", "") > prev.get("created_at", ""):
            by_therapist[tid] = m
    return sorted(by_therapist.values(), key=lambda m: m.get("created_at", ""), reverse=True)


def _next_id() -> str:
    return f"msg_{secrets.token_hex(8)}"


def send_text(user_id: str, therapist_id: str, text: str, sender: str) -> dict:
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
        "created_at": _now(),
    }
    return db.messages.put(msg)


def send_voice(user_id: str, therapist_id: str, voice_filename: str,
               duration_ms: int, sender: str) -> dict:
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
        "created_at": _now(),
    }
    return db.messages.put(msg)


# ── voice-note blob storage ──────────────────────────────────────────────────


def save_voice_file(content: bytes, ext: str = "m4a") -> str:
    name = f"{secrets.token_hex(10)}.{ext.lstrip('.')}"
    if VOICE_BUCKET:
        from google.cloud import storage  # type: ignore
        client = storage.Client()
        client.bucket(VOICE_BUCKET).blob(f"voice_notes/{name}").upload_from_string(
            content, content_type="audio/mp4"
        )
    else:
        VOICE_DIR.mkdir(parents=True, exist_ok=True)
        (VOICE_DIR / name).write_bytes(content)
    return name


def load_voice(filename: str) -> Optional[bytes]:
    """Return the audio bytes for a stored voice note, or None if not found.

    Filenames are validated to block path traversal before any lookup.
    """
    if not _SAFE_NAME.match(filename):
        return None
    if VOICE_BUCKET:
        from google.cloud import storage  # type: ignore
        blob = storage.Client().bucket(VOICE_BUCKET).blob(f"voice_notes/{filename}")
        return blob.download_as_bytes() if blob.exists() else None
    p = VOICE_DIR / filename
    return p.read_bytes() if p.exists() else None
