"""Synapse orchestrator tests."""

from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_health() -> None:
    """Health check returns ok."""
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ok"


def test_root() -> None:
    """Root endpoint returns message."""
    resp = client.get("/")
    assert resp.status_code == 200
    assert "Synapse" in resp.json()["message"]
