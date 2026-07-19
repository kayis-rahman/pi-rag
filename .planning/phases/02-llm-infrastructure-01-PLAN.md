# Phase 02 — LLM Infrastructure

**Plan:** 02-llm-infrastructure-01-PLAN
**Requirements:** SYN-08
**Status:** Draft
**Created:** 2026-07-19

## Goal

llama.cpp service running with Gemma 4 E4B. FastAPI proxy endpoint forwards requests to llama.cpp. GPUHub fallback when llama.cpp is unavailable.

## Tasks

### 2.1 LLM proxy service

**Files:**
- `app/services/llm.py` — **new** — LLM service with llama.cpp proxy + GPUHub fallback
- `app/models/llm.py` — **new** — ChatCompletionRequest/Response models
- `app/main.py` — **modified** — add `/health/llm` and `/api/llm/chat` endpoints

**Implementation:**
- `chat(request)` — tries llama.cpp first, falls back to GPUHub
- `health_check()` — checks llama.cpp connectivity
- Shared httpx.AsyncClient to avoid per-request TCP handshakes
- 120s timeout (llama.cpp can be slow on Pi 5)

**Endpoints:**
- `GET /health/llm` — reports llama.cpp reachability
- `POST /api/llm/chat` — proxy to llama.cpp /v1/chat/completions

### 2.2 systemd socket activation for llama.cpp

**Files:**
- `systemd/llama-cpp.service` — **new** — llama.cpp service unit
- `systemd/llama-cpp.socket` — **new** — socket activation unit
- `systemd/synapse.service` — **modify** — add After=llama-cpp.socket

**Behavior:**
- Socket unit listens on port 8081
- First connection triggers llama.cpp service start
- Model loads on first request
- After idle timeout (LLAMA_IDLE_TIMEOUT), llama.cpp exits
- systemd restarts it on next request

### 2.3 GPUHub fallback configuration

**Files:**
- `app/config.py` — **modify** — GPUHUB_ENDPOINT, GPUHUB_API_KEY already present
- `app/services/llm.py` — **modify** — fallback already implemented in 2.1

**Config needed:**
- GPUHUB_ENDPOINT = GPUHub URL
- GPUHUB_API_KEY = GPUHub API key
- GPUHUB_MODEL = qwen3-27b (default)

## Success Criteria

| # | Criterion | Verification |
|---|-----------|--------------|
| 1 | llama.cpp server responds to /health | `curl http://192.168.0.100:8080/health` |
| 2 | /api/llm/chat proxies to llama.cpp | POST returns valid chat.completion |
| 3 | /health/llm reports llama status | GET returns `{"llama":"ok"}` |
| 4 | GPUHub fallback configured | Settings present in .env |
| 5 | Socket activation unit created | systemd/llama-cpp.socket exists |

## Files Changed

| File | Action |
|------|--------|
| `app/services/llm.py` | **new** |
| `app/models/llm.py` | **new** |
| `app/main.py` | **modified** — add LLM endpoints |
| `app/config.py` | **modified** — update LLAMA_HOST to Pi IP |
| `systemd/llama-cpp.service` | **new** |
| `systemd/llama-cpp.socket` | **new** |
| `systemd/synapse.service` | **modify** — add dependency |
| `.env.example` | **modify** — add GPUHUB vars |

## Dependencies

Phase 1 — Foundation (done)

## Next Phase

Phase 3 — Data Sources (Gmail + GitHub Projects + iCal)