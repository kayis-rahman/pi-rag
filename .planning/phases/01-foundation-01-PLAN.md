# Phase 01 — Foundation

**Plan:** 01-foundation-01-PLAN
**Requirements:** SYN-01, SYN-12
**Status:** Draft
**Created:** 2026-07-18

## Goal

Python orchestrator running on Pi 5 with basic API endpoints. docker-compose brings up Qdrant + Redis + Open WebUI. systemd service configured for orchestrator.

## Tasks

### 1.1 FastAPI scaffolding

**File:** `app/main.py` — already exists with `/health` and `/` endpoints.

**Action:** Verify app starts, tests pass.

**Files:**
- `app/main.py` — FastAPI app entry point
- `app/config.py` — pydantic-settings
- `tests/test_main.py` — health + root tests
- `requirements.txt` — dependencies
- `pytest.ini` — pytest config (asyncio mode)

### 1.2 docker-compose for infrastructure

**File:** `docker-compose.yml` — already exists with qdrant, redis, openwebui.

**Action:** Verify compose up works.

### 1.3 systemd service for orchestrator

**File:** `systemd/synapse.service` — new.

**Action:** Create systemd unit for the orchestrator service.

**Contents:**
```ini
[Unit]
Description=Synapse Orchestrator
After=network.target
Wants=qdrant.service redis.service

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/workspace/ideas/synapse
ExecStart=/home/pi/workspace/ideas/synapse/.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8080
EnvironmentFile=/home/pi/workspace/ideas/synapse/.env
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

### 1.4 Deployment helper script

**File:** `systemd/synapse.automator.sh` — new.

**Action:** One-shot script to set up venv, install deps, enable systemd on Pi.

## Success Criteria

| # | Criterion | Verification |
|---|-----------|--------------|
| 1 | FastAPI starts and responds to health check | `curl /health` returns `{"status":"ok"}` |
| 2 | Pydantic settings loaded from .env | Settings object has correct defaults |
| 3 | docker-compose brings up Qdrant + Redis + Open WebUI | `docker compose up -d` succeeds |
| 4 | systemd service configured | `systemd/synapse.service` exists with correct unit |
| 5 | Tailscale connectivity verified | Manual check on Pi — `tailscale status` |

## Files Changed

| File | Action |
|------|--------|
| `app/main.py` | exists |
| `app/config.py` | exists |
| `app/__init__.py` | exists |
| `app/api/__init__.py` | exists |
| `app/services/__init__.py` | exists |
| `app/models/__init__.py` | exists |
| `app/infra/__init__.py` | exists |
| `tests/test_main.py` | exists |
| `tests/__init__.py` | exists |
| `requirements.txt` | exists (relaxed version pins) |
| `pytest.ini` | **new** |
| `docker-compose.yml` | exists |
| `.env.example` | exists |
| `systemd/synapse.service` | **new** |
| `systemd/synapse.automator.sh` | **new** |
| `README.md` | exists |

## Dependencies

None — Phase 1 has no upstream dependencies.

## Next Phase

Phase 2 — LLM Infrastructure (llama.cpp + systemd socket activation)