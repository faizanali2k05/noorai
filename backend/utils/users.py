"""User store + session management.

Backed by the shared persistence layer (Firestore in production, JSON files for
local dev — see ``utils.db``). Passwords are salted+hashed; session tokens are
opaque random strings stored **hashed at rest** so a datastore leak can't be
replayed.

Sessions use a two-token model:
  - **access token**  — short-lived (24h), sent on every request.
  - **refresh token** — long-lived; 90 days when "Remember Me" is on, 1 day
    otherwise. Exchanged at ``/api/auth/refresh`` for a fresh access token so
    users don't have to log in repeatedly. Refresh tokens rotate on use.
"""
from __future__ import annotations

import hashlib
import secrets
from datetime import datetime, timezone
from typing import Optional

from utils import db

ACCESS_TTL_SECONDS = 24 * 60 * 60            # 24 hours
REFRESH_TTL_REMEMBER = 90 * 24 * 60 * 60     # 90 days
REFRESH_TTL_SESSION = 24 * 60 * 60           # 1 day (no "remember me")


# ── helpers ──────────────────────────────────────────────────────────────────


def _now() -> int:
    return int(datetime.now(timezone.utc).timestamp())


def _iso() -> str:
    return datetime.now().astimezone().isoformat(timespec="seconds")


def _hash_pw(pw: str, salt: str) -> str:
    return hashlib.sha256(f"{salt}:{pw}".encode("utf-8")).hexdigest()


def _hash_token(raw: str) -> str:
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def _public(user: dict) -> dict:
    return {k: v for k, v in user.items() if k not in ("password_hash", "salt")}


# ── registration / login ──────────────────────────────────────────────────────


def register(email: str, password: str, name: str) -> tuple[Optional[dict], Optional[str]]:
    email = email.lower().strip()
    if db.users.where("email", email):
        return None, "Email already registered"
    salt = secrets.token_hex(8)
    user = {
        "user_id": f"usr_{secrets.token_hex(8)}",
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
        "created_at": _iso(),
    }
    db.users.put(user)
    session = _issue_session(user["user_id"], remember=True)
    return {"user": _public(user), **session}, None


def login(email: str, password: str, remember: bool = False) -> tuple[Optional[dict], Optional[str]]:
    email = email.lower().strip()
    matches = db.users.where("email", email)
    for u in matches:
        if u.get("password_hash") == _hash_pw(password, u.get("salt", "")):
            session = _issue_session(u["user_id"], remember=remember)
            return {"user": _public(u), **session}, None
    return None, "Invalid email or password"


# ── sessions ───────────────────────────────────────────────────────────────────


def _issue_session(user_id: str, remember: bool) -> dict:
    access_raw = secrets.token_urlsafe(32)
    refresh_raw = secrets.token_urlsafe(32)
    now = _now()
    refresh_ttl = REFRESH_TTL_REMEMBER if remember else REFRESH_TTL_SESSION
    db.tokens.put({
        "token_hash": _hash_token(access_raw),
        "user_id": user_id,
        "kind": "access",
        "created_at": _iso(),
        "expires_at": now + ACCESS_TTL_SECONDS,
    })
    db.tokens.put({
        "token_hash": _hash_token(refresh_raw),
        "user_id": user_id,
        "kind": "refresh",
        "remember": remember,
        "created_at": _iso(),
        "expires_at": now + refresh_ttl,
    })
    return {
        "token": access_raw,
        "refresh_token": refresh_raw,
        "expires_in": ACCESS_TTL_SECONDS,
    }


def user_from_token(raw_access: Optional[str]) -> Optional[dict]:
    """Resolve the user for a bearer access token, or None if invalid/expired."""
    if not raw_access:
        return None
    doc = db.tokens.get(_hash_token(raw_access))
    if not doc or doc.get("kind") != "access":
        return None
    if doc.get("expires_at", 0) < _now():
        db.tokens.delete(doc["token_hash"])  # purge expired
        return None
    return get_user(doc["user_id"])


def refresh_session(raw_refresh: Optional[str]) -> tuple[Optional[dict], Optional[str]]:
    """Exchange a refresh token for a new access+refresh pair (rotation)."""
    if not raw_refresh:
        return None, "Missing refresh token"
    doc = db.tokens.get(_hash_token(raw_refresh))
    if not doc or doc.get("kind") != "refresh":
        return None, "Invalid refresh token"
    if doc.get("expires_at", 0) < _now():
        db.tokens.delete(doc["token_hash"])
        return None, "Session expired, please log in again"
    user = get_user(doc["user_id"])
    if not user:
        db.tokens.delete(doc["token_hash"])
        return None, "User no longer exists"
    db.tokens.delete(doc["token_hash"])  # rotate: old refresh is now dead
    session = _issue_session(doc["user_id"], remember=bool(doc.get("remember")))
    return {"user": user, **session}, None


def revoke_session(raw_access: Optional[str], raw_refresh: Optional[str]) -> None:
    """Delete the presented access and refresh tokens (logout)."""
    for raw in (raw_access, raw_refresh):
        if raw:
            db.tokens.delete(_hash_token(raw))


# ── profile ────────────────────────────────────────────────────────────────────


def get_user(user_id: str) -> Optional[dict]:
    u = db.users.get(user_id)
    return _public(u) if u else None


def update_profile(user_id: str, patch: dict) -> Optional[dict]:
    allowed = {"name", "phone", "child_name", "child_age", "child_condition", "city", "area"}
    clean = {k: v for k, v in patch.items() if k in allowed}
    updated = db.users.update(user_id, clean)
    return _public(updated) if updated else None
