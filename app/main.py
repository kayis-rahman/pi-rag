"""Synapse Orchestrator — Personal AI Assistant Hub"""

from fastapi import FastAPI
from app.config import settings

app = FastAPI(
    title="Synapse",
    description="Personal AI assistant hub — GTD briefing + focus sessions",
    version="0.1.0",
)


@app.get("/health")
async def health() -> dict[str, str]:
    """Health check endpoint."""
    return {"status": "ok", "version": app.version}


@app.get("/")
async def root() -> dict[str, str]:
    """Root endpoint."""
    return {"message": "Synapse orchestrator running", "pi": settings.PI_HOSTNAME}
