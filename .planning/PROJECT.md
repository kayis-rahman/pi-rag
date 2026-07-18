# Synapse

## What This Is

Personal AI assistant hub hosted on Raspberry Pi 5 (8GB RAM).
One job: Daily GTD briefing + focus sessions (tasks, email, calendar, Pomodoro).

## Core Value

Wake up → get AI-generated briefing of day (email, tasks, calendar) → enter focus session with adaptive Pomodoro → stay in flow. All local, private, voice-enabled.

## Key Differentiators

- **Local-first**: LLM runs on Pi 5 (Gemma 4 E4B) — no cloud dependency
- **Privacy**: Email/tasks processed locally, nothing leaves your network
- **Adaptive**: LLM detects burnout, adjusts Pomodoro intervals dynamically
- **Voice**: IndicWhisper (Malayalam + English) input, Parler-TTS output
- **Tailscale**: Zero-config networking from iPhone to Pi

## Repositories

| Repo | Role |
|------|------|
| `kayis-rahman/synapse` | Python orchestrator, Pi services, GTD logic |
| `kayis-rahman/time-beam` | iOS/macOS SwiftUI Pomodoro app |

## Requirements

### Validated

- ✓ Raspberry Pi 5 (8GB) available — hardware confirmed
- ✓ Tailscale network operational — Pi reachable from iPhone
- ✓ Gemma 4 E4B quantized model available — runs on Pi 5
- ✓ TimeBeam iOS app exists — phase 02-03 complete
- ✓ GitHub Projects board (Kayis HQ) — issue tracking configured

### Active

- [x] SYN-01: Python orchestrator scaffolding (FastAPI + pydantic)
- [ ] SYN-02: Gmail API integration (email briefing)
- [ ] SYN-03: GitHub Projects integration (task polling)
- [ ] SYN-04: iCal integration (.ics polling)
- [ ] SYN-05: GTD briefing prompt pipeline (LLM orchestration)
- [ ] SYN-06: Qdrant RAG integration (long-term memory)
- [ ] SYN-07: Redis session state management
- [ ] SYN-08: llama.cpp service with systemd socket activation
- [ ] SYN-09: TimeBeam API contract (session sync endpoints)
- [ ] SYN-10: Voice pipeline (IndicWhisper + Parler-TTS)
- [ ] SYN-11: Open WebUI fallback configuration
- [x] SYN-12: Pi 5 deployment automation

### Out of Scope

- Home automation (yet)
- AI HAT accelerator
- Paid iOS app distribution (personal use first)
- Multi-user support (single user v1)
- Real-time chat interface (Pomodoro + briefing only)

## Context

Greenfield project. Old Synapse (Spring Boot memory agent) archived to `archive/spring-boot-memory-agent` branch.

## Constraints

- **Hardware**: Pi 5 8GB RAM — model must fit in memory
- **Network**: Tailscale only — no public exposure
- **Privacy**: All processing local — no external API calls except data sources (Gmail/GitHub/iCal)
- **Power**: Pi must be stable 24/7 — graceful degradation on failure

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Python over Java | Lighter weight, better AI ecosystem | ✓ Aligned with llama.cpp/Qdrant Python clients |
| FastAPI over Flask | async/await, auto OpenAPI docs | ✓ Better for real-time session updates |
| Gemma 4 E4B | Fits Pi 5 8GB, good multilingual | ✓ Quantized 4-bit ~3GB RAM |
| systemd socket activation | Auto-unload idle LLM | ✓ Saves RAM when not in use |
| Tailscale networking | Zero-config, encrypted | ✓ iPhone ↔ Pi without port forwarding |
| Qdrant for RAG | Proven from old Synapse | ✓ Vector search for memory/context |
| Redis for sessions | Fast, TTL support | ✓ Session state + Pomodoro timers |
