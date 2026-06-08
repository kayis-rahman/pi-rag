# Synapse Memory Agent - Archived

**Archived:** 2026-06-08
**Reason:** Scope pivot — Synapse redefined as personal AI assistant hub (GTD + Pomodoro) on Raspberry Pi 5

## What Was Archived

Java/Spring Boot 3.3.5 memory agent with:
- Episodic memory (Redis + PostgreSQL)
- Semantic memory (Qdrant vectors)
- Knowledge graph (SQLite triple store)
- Unified memory facade
- LLM routing (Claude via GPUHub)
- Agent framework (DeveloperAssistant)
- Session management

## Progress at Archive

- Phase 1 (Database Foundation): Not started
- Phase 2 (Memory Core): 64% complete (3 plans done)
- Phase 3-7: Not started

## Key Artifacts Preserved

- Memory architecture patterns (facade, dual-write, async indexing)
- LLM routing strategies (round-robin, tiered, adaptive)
- Test infrastructure (JUnit 5, E2E tests)
- Embedding configuration system

## New Synapse Scope

- Python backend orchestrator
- llama.cpp + Gemma 4 E4B (local on Pi 5)
- Qdrant (RAG/memory) + Redis (session state)
- iOS Pomodoro app (time-beam repo)
- GTD briefing (Gmail + GitHub + iCal)
- Voice: IndicWhisper + Indic Parler-TTS
