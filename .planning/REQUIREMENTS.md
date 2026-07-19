# Requirements: Synapse

**Defined:** 2026-06-08
**Core Value:** Daily GTD briefing + adaptive focus sessions, all local on Pi 5

## v1 Requirements

### Orchestrator Core

- [x] **SYN-01**: Python orchestrator scaffolding (FastAPI + pydantic-settings)
- [x] **SYN-12**: Pi 5 deployment automation (systemd + docker-compose)

### Data Sources

- [ ] **SYN-02**: Gmail API integration — fetch unread + today's emails for briefing
- [ ] **SYN-03**: GitHub Projects integration — poll task board for active items
- [ ] **SYN-04**: iCal integration — poll .ics URLs for today's events

### GTD Briefing Pipeline

- [ ] **SYN-05**: GTD briefing prompt pipeline — assemble context → LLM → formatted briefing
- [ ] **SYN-06**: Qdrant RAG integration — store/retrieve past briefings for continuity
- [ ] **SYN-07**: Redis session state — track current session + user preferences

### LLM Infrastructure

- [ ] **SYN-08**: llama.cpp service — Gemma 4 E4B with systemd socket activation
- [ ] **SYN-11**: Open WebUI fallback — configure as secondary interface

### TimeBeam Integration

- [ ] **SYN-09**: TimeBeam API contract — session sync endpoints (start/stop/pause/status)
- [ ] **SYN-10**: Voice pipeline — IndicWhisper ASR + Parler-TTS output

### Session Management

- [ ] **SESS-01**: Focus session lifecycle (start → work → break → complete)
- [ ] **SESS-02**: Burnout detection (LLM analyzes session patterns)
- [ ] **SESS-03**: Dynamic interval adjustment (adaptive Pomodoro)
- [ ] **SESS-04**: Session history persistence (Qdrant + Redis)

## v2 Requirements

### Advanced Briefing

- **BRF-01**: Weekly review briefing (Friday summary + weekend prep)
- **BRF-02**: Context-aware task prioritization (LLM ranks by urgency/effort)
- **BRF-03**: Email draft suggestions (LLM proposes replies)

### Voice Enhancement

- **VCE-01**: Multi-language briefing output (Malayalam/English toggle)
- **VCE-02**: Voice commands during sessions ("next task", "take break")
- **VCE-03**: Conversation memory (remember preferences across sessions)

### Analytics

- **ANL-01**: Daily productivity score (focus time vs. distractions)
- **ANL-02**: Weekly trends report (best/worst focus windows)
- **ANL-03**: Burnout risk indicator (pattern analysis)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Home automation | Phase 2+ consideration |
| AI HAT accelerator | Not needed for E4B on Pi 5 |
| Multi-user | Single user v1 |
| Public deployment | Personal use, Tailscale only |
| Telegram/Slack | iOS app + WebUI sufficient |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SYN-01 | Phase 1 | Done |
| SYN-12 | Phase 1 | Done |
| SYN-08 | Phase 2 | Done |
| SYN-02 | Phase 3 | Pending |
| SYN-03 | Phase 3 | Pending |
| SYN-04 | Phase 3 | Pending |
| SYN-05 | Phase 4 | Pending |
| SYN-06 | Phase 4 | Pending |
| SYN-07 | Phase 4 | Pending |
| SYN-09 | Phase 5 | Pending |
| SYN-10 | Phase 5 | Pending |
| SYN-11 | Phase 6 | Pending |
| SESS-01 | Phase 5 | Pending |
| SESS-02 | Phase 5 | Pending |
| SESS-03 | Phase 5 | Pending |
| SESS-04 | Phase 5 | Pending |
