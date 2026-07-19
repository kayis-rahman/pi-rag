"""Tests for LLM service."""

from unittest.mock import AsyncMock, MagicMock, patch

from app.models.llm import ChatCompletionRequest, ChatMessage
from app.services.llm import chat, health_check


def _mock_response() -> MagicMock:
    resp = MagicMock()
    resp.raise_for_status = MagicMock()
    resp.json.return_value = {
        "id": "chatcmpl-abc",
        "object": "chat.completion",
        "created": 1700000000,
        "model": "test-model",
        "choices": [{"index": 0, "finish_reason": "stop", "message": {"role": "assistant", "content": "Hello"}}],
        "usage": {"prompt_tokens": 10, "completion_tokens": 5, "total_tokens": 15},
        "system_fingerprint": "test",
    }
    return resp


async def test_chat_sends_to_llama() -> None:
    """Chat request is forwarded to llama.cpp."""
    mock_resp = _mock_response()
    mock_client = AsyncMock()
    mock_client.post.return_value = mock_resp
    mock_client.__aenter__ = AsyncMock(return_value=mock_client)
    mock_client.__aexit__ = AsyncMock(return_value=None)

    with patch("app.services.llm._get_llama_client", return_value=mock_client):
        req = ChatCompletionRequest(
            model="test-model",
            messages=[ChatMessage(role="user", content="Hi")],
            max_tokens=64,
        )
        result = await chat(req)

    assert result.model == "test-model"
    assert result.choices[0]["message"]["content"] == "Hello"


async def test_chat_falls_back_to_gpu() -> None:
    """When llama.cpp fails, GPUHub is used as fallback."""
    mock_resp = _mock_response()
    mock_client = AsyncMock()
    mock_client.post.return_value = mock_resp
    mock_client.__aenter__ = AsyncMock(return_value=mock_client)
    mock_client.__aexit__ = AsyncMock(return_value=None)

    with patch("app.services.llm._get_llama_client", side_effect=Exception("down")):
        with patch("app.services.llm._get_gpu_client", return_value=mock_client):
            with patch("app.config.settings.GPUHUB_ENDPOINT", "http://gpu:8080"):
                req = ChatCompletionRequest(
                    model="test-model",
                    messages=[ChatMessage(role="user", content="Hi")],
                )
                result = await chat(req)

    assert result.model == "test-model"


async def test_health_check_ok() -> None:
    """Health check reports llama.cpp status."""
    mock_resp = MagicMock()
    mock_resp.raise_for_status = MagicMock()
    mock_resp.json.return_value = {"status": "ok"}
    mock_client = AsyncMock()
    mock_client.get.return_value = mock_resp
    mock_client.__aenter__ = AsyncMock(return_value=mock_client)
    mock_client.__aexit__ = AsyncMock(return_value=None)

    with patch("app.services.llm._get_llama_client", return_value=mock_client):
        result = await health_check()

    assert result["llama"] == "ok"