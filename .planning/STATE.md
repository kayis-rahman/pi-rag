---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: "Synapse Personal AI Hub"
status: planning
last_updated: "2026-06-08T19:00:00.000Z"
progress:
  total_phases: 6
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
---

# Synapse — Project State

## Project Reference

**Name**: Synapse Personal AI Hub
**Core Value**: Daily GTD briefing + adaptive focus sessions, all local on Pi 5
**Current Phase**: 01-foundation
**Next Action**: Plan Phase 1 (Orchestrator scaffolding + Pi deployment)

---

## Current Position

| Attribute | Value |
|-----------|-------|
| Phase | 01-foundation |
| Plan | none |
| Status | Greenfield — old Spring Boot code archived |
| Progress | `░░░░░░░░` 0% |

---

## Accumulated Context

### Decisions

| Decision | Rationale | Status |
|----------|-----------|--------|
| Python/FastAPI backend | Lighter weight, better AI ecosystem | Approved |
| Gemma 4 E4B | Fits Pi 5 8GB, good multilingual | Approved |
| systemd socket activation | Auto-unload idle LLM | Approved |
| Tailscale networking | Zero-config, encrypted | Approved |
| Qdrant for RAG | Proven from old Synapse | Approved |
| Redis for sessions | Fast, TTL support | Approved |
| TimeBeam for iOS | Existing repo, phase 02-03 done | Approved |

### Key Files

| File | Purpose | Location |
|------|---------|----------|
| CLAUDE.md | Project definition | root |
| PROJECT.md | Scope and decisions | `.planning/` |
| REQUIREMENTS.md | v1/v2 requirements | `.planning/` |
| ROADMAP.md | Phase plan | `.planning/` |

### Technical Stack

| Category | Technology |
|----------|------------|
| Language | Python 3.11+ |
| Framework | FastAPI |
| LLM Runtime | llama.cpp |
| Model | Gemma 4 E4B (Q4 quantized) |
| Vector DB | Qdrant |
| Session DB | Redis |
| Fallback UI | Open WebUI |
| iOS App | TimeBeam (SwiftUI) |
| Network | Tailscale |

### Archive

| Branch | Content |
|--------|---------|
| `archive/spring-boot-memory-agent` | Old Synapse v1 (Java/Spring Boot memory agent) |

---

## Sessions

| Date | Topic | Key Outcomes |
|------|-------|--------------|
| 2026-06-08 | Scope pivot | Old Spring Boot archived, new scope defined, git repo restructured |

---

## Blockers

None at this time.

---

## Notes

- Old Synapse (Spring Boot memory agent) archived to `archive/spring-boot-memory-agent`
- TimeBeam iOS repo at `kayis-rahman/time-beam` — phase 02-03 complete
- Pi hostname: `dietpi.local` via Tailscale
- GitHub Project #7 "Kayis's HQ" for issue tracking
