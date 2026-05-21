"""Persistence layer for NoorAI.

Production runs on **Google Firestore** (durable, serverless, shared across all
Cloud Run instances). Local development uses **JSON files** under ``data/`` so
the app runs with zero cloud setup. Both backends store *real* user data — the
JSON backend is a development store, not mock data.

Why this exists
---------------
The backend is deployed to Cloud Run, whose container filesystem is ephemeral.
Writing users/tokens/chats/bookings to JSON files on that disk silently loses
them on every redeploy, cold start, or scale event. Routing all writes through
Firestore is what makes data actually persist.

Backend selection (``NOORAI_STORE`` env):
  - ``firestore`` -> always Firestore
  - ``json``      -> always JSON files
  - unset         -> Firestore when running on Cloud Run (``K_SERVICE`` set) or
                     when ``GOOGLE_CLOUD_PROJECT`` is configured; otherwise JSON.

A collection is addressed by a stable id field (``user_id``, ``token_hash``,
``message_id``, ``booking_id`` …) so lookups are O(1) in Firestore and the
local JSON files keep their existing list shape.
"""
from __future__ import annotations

import json
import os
import threading
from pathlib import Path
from typing import Any, Optional

DATA_DIR = Path(__file__).resolve().parent.parent / "data"

# ── Backend selection ───────────────────────────────────────────────────────


def _use_firestore() -> bool:
    mode = os.environ.get("NOORAI_STORE", "").strip().lower()
    if mode == "firestore":
        return True
    if mode == "json":
        return False
    # Auto: prefer Firestore when running on Cloud Run or with a GCP project set.
    return bool(os.environ.get("K_SERVICE") or os.environ.get("GOOGLE_CLOUD_PROJECT"))


# ── Firestore backend ───────────────────────────────────────────────────────


class _FirestoreBackend:
    """Thin wrapper over google-cloud-firestore.

    Uses Application Default Credentials — on Cloud Run that is the service
    account, no key file needed. Fails loudly if the client can't initialise so
    a misconfigured deploy is obvious instead of silently dropping data.
    """

    def __init__(self) -> None:
        try:
            from google.cloud import firestore  # type: ignore
        except Exception as exc:  # pragma: no cover - import guard
            raise RuntimeError(
                "NOORAI_STORE resolved to Firestore but google-cloud-firestore "
                "is not installed. Add it to requirements.txt."
            ) from exc
        self._client = firestore.Client()

    def list(self, collection: str) -> list[dict]:
        return [d.to_dict() for d in self._client.collection(collection).stream()]

    def get(self, collection: str, doc_id: str) -> Optional[dict]:
        snap = self._client.collection(collection).document(str(doc_id)).get()
        return snap.to_dict() if snap.exists else None

    def put(self, collection: str, doc_id: str, doc: dict) -> dict:
        self._client.collection(collection).document(str(doc_id)).set(doc)
        return doc

    def delete(self, collection: str, doc_id: str) -> None:
        self._client.collection(collection).document(str(doc_id)).delete()

    def where(self, collection: str, field: str, value: Any) -> list[dict]:
        q = self._client.collection(collection).where(field, "==", value)
        return [d.to_dict() for d in q.stream()]


# ── JSON backend (local dev) ────────────────────────────────────────────────


class _JsonBackend:
    """JSON-file store with a process-wide lock for safe concurrent writes.

    Each collection is one file: ``data/<collection>.json`` holding a list of
    documents, matching the repo's existing data files.
    """

    _lock = threading.RLock()

    def _path(self, collection: str) -> Path:
        return DATA_DIR / f"{collection}.json"

    def _read(self, collection: str) -> list[dict]:
        path = self._path(collection)
        if not path.exists():
            return []
        txt = path.read_text(encoding="utf-8").strip()
        if not txt:
            return []
        data = json.loads(txt)
        # Legacy tokens.json was a {token: user_id} map — ignore; new schema is a list.
        return data if isinstance(data, list) else []

    def _write(self, collection: str, docs: list[dict]) -> None:
        path = self._path(collection)
        path.parent.mkdir(parents=True, exist_ok=True)
        tmp = path.with_suffix(".json.tmp")
        tmp.write_text(json.dumps(docs, indent=2), encoding="utf-8")
        tmp.replace(path)  # atomic on the same filesystem

    def list(self, collection: str) -> list[dict]:
        with self._lock:
            return self._read(collection)

    def get(self, collection: str, doc_id: str) -> Optional[dict]:
        with self._lock:
            for d in self._read(collection):
                if str(d.get("_id")) == str(doc_id):
                    return d
        return None

    def put(self, collection: str, doc_id: str, doc: dict) -> dict:
        with self._lock:
            docs = self._read(collection)
            stored = {**doc, "_id": str(doc_id)}
            for i, d in enumerate(docs):
                if str(d.get("_id")) == str(doc_id):
                    docs[i] = stored
                    break
            else:
                docs.append(stored)
            self._write(collection, docs)
            return stored

    def delete(self, collection: str, doc_id: str) -> None:
        with self._lock:
            docs = [d for d in self._read(collection) if str(d.get("_id")) != str(doc_id)]
            self._write(collection, docs)

    def where(self, collection: str, field: str, value: Any) -> list[dict]:
        with self._lock:
            return [d for d in self._read(collection) if d.get(field) == value]


# ── Public collection handle ─────────────────────────────────────────────────

_backend: Optional[Any] = None


def _get_backend():
    global _backend
    if _backend is None:
        _backend = _FirestoreBackend() if _use_firestore() else _JsonBackend()
    return _backend


def backend_name() -> str:
    return "firestore" if _use_firestore() else "json"


class Collection:
    """A document collection addressed by a natural id field.

    ``id_field`` is the attribute on each document used as its primary key
    (e.g. ``user_id``). The backend stores under that id so reads are O(1).
    """

    def __init__(self, name: str, id_field: str) -> None:
        self.name = name
        self.id_field = id_field

    def _id_of(self, doc: dict) -> str:
        doc_id = doc.get(self.id_field)
        if doc_id is None:
            raise ValueError(f"document for '{self.name}' missing id field '{self.id_field}'")
        return str(doc_id)

    def all(self) -> list[dict]:
        return [self._strip(d) for d in _get_backend().list(self.name)]

    def get(self, doc_id: str) -> Optional[dict]:
        return self._strip(_get_backend().get(self.name, doc_id))

    def put(self, doc: dict) -> dict:
        """Insert or replace a document keyed by its id field."""
        return self._strip(_get_backend().put(self.name, self._id_of(doc), dict(doc)))

    def update(self, doc_id: str, patch: dict) -> Optional[dict]:
        existing = _get_backend().get(self.name, doc_id)
        if existing is None:
            return None
        existing.update(patch)
        existing.pop("_id", None)
        existing[self.id_field] = doc_id
        return self.put(existing)

    def delete(self, doc_id: str) -> None:
        _get_backend().delete(self.name, doc_id)

    def where(self, field: str, value: Any) -> list[dict]:
        return [self._strip(d) for d in _get_backend().where(self.name, field, value)]

    @staticmethod
    def _strip(doc: Optional[dict]) -> Optional[dict]:
        # Drop the JSON backend's internal "_id" mirror from anything we hand out.
        if doc is None:
            return None
        if "_id" in doc:
            doc = {k: v for k, v in doc.items() if k != "_id"}
        return doc


# Collection handles used across the backend.
users = Collection("users", "user_id")
tokens = Collection("tokens", "token_hash")
messages = Collection("messages", "message_id")
bookings = Collection("bookings", "booking_id")
service_bookings = Collection("service_bookings", "booking_id")
traces = Collection("traces", "trace_id")
