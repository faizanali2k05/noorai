"""Realtime LLM client for NoorAI.

Provider-agnostic JSON helper used by the agent pipeline for natural-language
understanding. OpenAI is the primary provider; Gemini is an optional fallback.
Set NOORAI_OFFLINE_MODE=1 to disable all LLM calls (regex fallback only).
"""
from __future__ import annotations

import json
import os
from typing import Optional

OPENAI_MODEL = os.environ.get("OPENAI_MODEL", "gpt-4o-mini")
GEMINI_MODEL = os.environ.get("GEMINI_MODEL", "gemini-2.0-flash")
OPENAI_URL = "https://api.openai.com/v1/chat/completions"


def _active_provider() -> Optional[str]:
    if os.environ.get("NOORAI_OFFLINE_MODE") == "1":
        return None
    if os.environ.get("OPENAI_API_KEY"):
        return "openai"
    if os.environ.get("GEMINI_API_KEY"):
        return "gemini"
    return None


def llm_status() -> dict:
    """Report whether realtime LLM understanding is active and which provider.

    Surfaced via /api/health so misconfiguration is visible instead of
    silently degrading to the regex fallback.
    """
    if os.environ.get("NOORAI_OFFLINE_MODE") == "1":
        return {"enabled": False, "reason": "offline_mode"}
    provider = _active_provider()
    if provider == "openai":
        return {"enabled": True, "provider": "openai", "model": OPENAI_MODEL}
    if provider == "gemini":
        return {"enabled": True, "provider": "gemini", "model": GEMINI_MODEL}
    return {"enabled": False, "reason": "no_api_key"}


def chat_json(system_prompt: str, user_text: str) -> Optional[dict]:
    """Return a parsed JSON object from the configured LLM, or None on failure.

    The caller is expected to fall back to a deterministic parser when this
    returns None so the demo always works.
    """
    provider = _active_provider()
    if provider == "openai":
        return _openai_json(system_prompt, user_text)
    if provider == "gemini":
        return _gemini_json(system_prompt, user_text)
    return None


def _openai_json(system_prompt: str, user_text: str) -> Optional[dict]:
    try:
        import httpx
    except Exception:
        print("[llm] httpx not installed; cannot call OpenAI")
        return None
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        return None
    try:
        resp = httpx.post(
            OPENAI_URL,
            headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
            },
            json={
                "model": OPENAI_MODEL,
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_text},
                ],
                "response_format": {"type": "json_object"},
                "temperature": 0.2,
            },
            timeout=30.0,
        )
        resp.raise_for_status()
        content = resp.json()["choices"][0]["message"]["content"]
        return json.loads(content)
    except Exception as exc:
        print(f"[llm] OpenAI call failed ({OPENAI_MODEL}): {exc}")
        return None


def _gemini_json(system_prompt: str, user_text: str) -> Optional[dict]:
    try:
        import google.generativeai as genai
    except Exception:
        print("[llm] google-generativeai not installed; cannot call Gemini")
        return None
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        return None
    try:
        genai.configure(api_key=api_key)
        model = genai.GenerativeModel(
            GEMINI_MODEL,
            system_instruction=system_prompt,
            generation_config={"response_mime_type": "application/json"},
        )
        resp = model.generate_content(user_text)
        return json.loads(resp.text)
    except Exception as exc:
        print(f"[llm] Gemini call failed ({GEMINI_MODEL}): {exc}")
        return None
