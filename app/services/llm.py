"""LLM service — proxy to llama.cpp with GPUHub fallback."""

from __future__ import annotations

import logging
import time

import httpx
from app.config import settings
from app.models.llm import ChatCompletionRequest, ChatCompletionResponse

logger = logging.getLogger(__name__)

# Shared client avoids per-request TCP handshakes.
_llama_client: httpx.AsyncClient | None = None
_gpu_client: httpx.AsyncClient | None = None


def _get_llama_client() -> httpx.AsyncClient:
    global _llama_client
    if _llama_client is None:
        _llama_client = httpx.AsyncClient(
            base_url=settings.LLAMA_HOST,
            timeout=httpx.Timeout(120.0, connect=10.0),
        )
    return _llama_client


def _get_gpu_client() -> httpx.AsyncClient:
    global _gpu_client
    if _gpu_client is None:
        _gpu_client = httpx.AsyncClient(
            base_url=settings.GPUHUB_ENDPOINT,
            headers={"Authorization": f"Bearer {settings.GPUHUB_API_KEY}"},
            timeout=httpx.Timeout(120.0, connect=10.0),
        )
    return _gpu_client


async def chat(request: ChatCompletionRequest) -> ChatCompletionResponse:
    """Send chat completion request — tries llama.cpp first, falls back to GPUHub."""
    try:
        return await _chat_via_llama(request)
    except Exception:
        if settings.GPUHUB_ENDPOINT:
            logger.warning("llama.cpp unavailable — falling back to GPUHub")
            return await _chat_via_gpu(request)
        raise


async def _chat_via_llama(request: ChatCompletionRequest) -> ChatCompletionResponse:
    client = _get_llama_client()
    payload = {
        "model": request.model,
        "messages": [{"role": m.role, "content": m.content} for m in request.messages],
        "temperature": request.temperature,
        "max_tokens": request.max_tokens,
        "top_p": request.top_p,
        "stream": request.stream,
    }
    if request.stop:
        payload["stop"] = request.stop

    resp = await client.post("/v1/chat/completions", json=payload)
    resp.raise_for_status()
    data = resp.json()
    return ChatCompletionResponse.model_validate(data)


async def _chat_via_gpu(request: ChatCompletionRequest) -> ChatCompletionResponse:
    client = _get_gpu_client()
    payload = {
        "model": request.model,
        "messages": [{"role": m.role, "content": m.content} for m in request.messages],
        "temperature": request.temperature,
        "max_tokens": request.max_tokens,
        "top_p": request.top_p,
    }
    if request.stop:
        payload["stop"] = request.stop

    resp = await client.post("/v1/chat/completions", json=payload)
    resp.raise_for_status()
    data = resp.json()
    return ChatCompletionResponse.model_validate(data)


async def health_check() -> dict[str, object]:
    """Check if llama.cpp is reachable."""
    try:
        client = _get_llama_client()
        resp = await client.get("/health")
        return {"llama": "ok", "gpuhub": "skipped"}
    except Exception as e:
        return {"llama": "unreachable", "error": str(e)}