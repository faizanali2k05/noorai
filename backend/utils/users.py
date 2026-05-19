"""Simple user store — JSON-backed, hashed-password auth, opaque session tokens.

Not production-grade. For the hackathon demo it gives us a real signup/login flow
without pulling in Firebase or a full auth stack.
"""
from __future__ import annotations

import hashlib
import json
import secrets
from datetime import datetime
from pathlib import Path
from typing import Optional

DATA_DIR = Path(__file__).resolve().parent.parent / "data"
USERS_FILE = DATA_DIR / "users.json"
TOKENS_FILE = DATA_DIR / "tokens.json"


def _read(path: Path) -> list[dict] | dict:
    if not path.exists():
        return {} if path.name == "tokens.json" else []
    txt = path.read_text(encoding="utf-8") or ""
    if not txt.strip():
        return {} if path.name == "tokens.json" else []
    return json.loads(txt)


def _write(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2), encoding="utf-8")


def _hash_pw(pw: str, salt: str) -> str:
    return hashlib.sha256(f"{salt}:{pw}".encode("utf-8")).hexdigest()


def _public(user: dict) -> dict:
    return {k: v for k, v in user.items() if k not in ("password_hash", "salt")}


def register(email: str, password: str, name: str) -> tuple[Optional[dict], Optional[str]]:
    users: list[dict] = _read(USERS_FILE)  # type: ignore
    email = email.lower().strip()
    if any(u["email"] == email for u in users):
        return None, "Email already registered"
    salt = secrets.token_hex(8)
    seq = len(users) + 1
    user = {
        "user_id": f"u{seq:03d}",
        "email": email,
        "name": name.strip(),
        "salt": salt,
        "password_hash": _hash_pw(password, salt),
        "child_name": None,
        "child_age": None,
        "child_condition": None,
        "city": None,
        "area": None,
        "phone": None,
        "created_at": datetime.now().astimezone().isoformat(timespec="seconds"),
    }
    users.append(user)
    _write(USERS_FILE, users)
    token = _issue_token(user["user_id"])
    return {"user": _public(user), "token": token}, None


def login(email: str, password: str) -> tuple[Optional[dict], Optional[str]]:
    users: list[dict] = _read(USERS_FILE)  # type: ignore
    email = email.lower().strip()
    for u in users:
        if u["email"] == email and u["password_hash"] == _hash_pw(password, u["salt"]):
            token = _issue_token(u["user_id"])
            return {"user": _public(u), "token": token}, None
    return None, "Invalid email or password"


def _issue_token(user_id: str) -> str:
    tokens: dict = _read(TOKENS_FILE)  # type: ignore
    token = secrets.token_urlsafe(24)
    tokens[token] = user_id
    _write(TOKENS_FILE, tokens)
    return token


def user_from_token(token: Optional[str]) -> Optional[dict]:
    if not token:
        return None
    tokens: dict = _read(TOKENS_FILE)  # type: ignore
    uid = tokens.get(token)
    if not uid:
        return None
    return get_user(uid)


def get_user(user_id: str) -> Optional[dict]:
    users: list[dict] = _read(USERS_FILE)  # type: ignore
    for u in users:
        if u["user_id"] == user_id:
            return _public(u)
    return None


def update_profile(user_id: str, patch: dict) -> Optional[dict]:
    allowed = {"name", "phone", "child_name", "child_age", "child_condition", "city", "area"}
    users: list[dict] = _read(USERS_FILE)  # type: ignore
    for u in users:
        if u["user_id"] == user_id:
            for k, v in patch.items():
                if k in allowed:
                    u[k] = v
            _write(USERS_FILE, users)
            return _public(u)
    return None
