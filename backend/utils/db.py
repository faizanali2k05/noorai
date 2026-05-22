"""Persistence layer for NoorAI — backed by **Supabase** (Postgres + Storage).

Every table is created once by ``database.sql`` (see the repo root). The backend
connects with the project's **service_role key** so it bypasses Row Level
Security and has full read/write access; the mobile app never touches Supabase
directly, it goes through this API.

Configuration is just two environment variables:
  - ``SUPABASE_URL`` — https://<project-ref>.supabase.co
  - ``SUPABASE_KEY`` — the service_role key (Settings → API)

A collection is addressed by a stable id field (``user_id``, ``token_hash``,
``message_id``, ``booking_id`` …) which is the table's primary key, so lookups
and upserts are O(1).
"""
from __future__ import annotations

import os
from typing import Any, Optional

# ── Supabase client (lazy singleton) ─────────────────────────────────────────

_client: Optional[Any] = None


def get_client():
    """Return a shared Supabase client, creating it on first use.

    Fails loudly if the credentials are missing so a misconfigured deploy is
    obvious instead of silently dropping data.
    """
    global _client
    if _client is None:
        url = os.environ.get("SUPABASE_URL", "").strip()
        key = os.environ.get("SUPABASE_KEY", "").strip()
        if not url or not key:
            raise RuntimeError(
                "SUPABASE_URL and SUPABASE_KEY must be set. Copy them from your "
                "Supabase project (Settings → API) into the backend environment."
            )
        try:
            from supabase import create_client  # type: ignore
        except Exception as exc:  # pragma: no cover - import guard
            raise RuntimeError(
                "supabase is not installed. Add 'supabase' to requirements.txt."
            ) from exc
        _client = create_client(url, key)
    return _client


def backend_name() -> str:
    return "supabase"


# ── Public collection handle ─────────────────────────────────────────────────


class Collection:
    """A Postgres table addressed by its primary-key field.

    ``id_field`` is the column used as the natural key (e.g. ``user_id``).
    """

    def __init__(self, name: str, id_field: str) -> None:
        self.name = name
        self.id_field = id_field

    def _table(self):
        return get_client().table(self.name)

    def _id_of(self, doc: dict) -> str:
        doc_id = doc.get(self.id_field)
        if doc_id is None:
            raise ValueError(f"document for '{self.name}' missing id field '{self.id_field}'")
        return str(doc_id)

    def all(self) -> list[dict]:
        return self._table().select("*").execute().data or []

    def get(self, doc_id: str) -> Optional[dict]:
        rows = (
            self._table().select("*").eq(self.id_field, str(doc_id)).limit(1).execute().data
        )
        return rows[0] if rows else None

    def put(self, doc: dict) -> dict:
        """Insert or replace a document keyed by its id field."""
        payload = dict(doc)
        payload[self.id_field] = self._id_of(payload)
        rows = self._table().upsert(payload, on_conflict=self.id_field).execute().data
        return rows[0] if rows else payload

    def update(self, doc_id: str, patch: dict) -> Optional[dict]:
        rows = (
            self._table().update(dict(patch)).eq(self.id_field, str(doc_id)).execute().data
        )
        return rows[0] if rows else None

    def delete(self, doc_id: str) -> None:
        self._table().delete().eq(self.id_field, str(doc_id)).execute()

    def where(self, field: str, value: Any) -> list[dict]:
        return self._table().select("*").eq(field, value).execute().data or []


# Collection handles used across the backend.
users = Collection("users", "user_id")
tokens = Collection("tokens", "token_hash")
messages = Collection("messages", "message_id")
bookings = Collection("bookings", "booking_id")
service_bookings = Collection("service_bookings", "booking_id")
traces = Collection("traces", "trace_id")
