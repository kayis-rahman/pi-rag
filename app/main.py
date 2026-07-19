"""Synapse Orchestrator — Personal AI Assistant Hub"""

from fastapi import FastAPI
from app.config import settings
from app.services.llm import chat, health_check
from app.models.llm import ChatCompletionRequest

app = FastAPI(
    title="Synapse",
    description="Personal AI assistant hub — GTD briefing + focus sessions",
    version="0.1.0",
)


@app.get("/health")
async def health() -> dict[str, str]:
    """Health check endpoint."""
    return {"status": "ok", "version": app.version}


@app.get("/health/llm")
async def llm_health() -> dict[str, object]:
    """Check if llama.cpp is reachable."""
    return await health_check()


@app.get("/")
async def root() -> dict[str, str]:
    """Root endpoint."""
    return {"message": "Synapse orchestrator running", "pi": settings.PI_HOSTNAME}


@app.post("/api/llm/chat")
async def llm_chat(request: ChatCompletionRequest) -> dict:
    """Proxy chat completion to llama.cpp (with GPUHub fallback)."""
    result = await chat(request)
    return result.model_dump()