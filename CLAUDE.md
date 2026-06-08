# Synapse — Personal AI Assistant Hub

## What This Is

Personal AI assistant hub hosted on Raspberry Pi 5 (8GB RAM).
One job: Daily GTD briefing + focus sessions (tasks, email, calendar, Pomodoro).

## Architecture

```
┌─────────────────────────────────────────────────┐
│                 Raspberry Pi 5                   │
│                                                  │
│  ┌──────────────┐  ┌──────────────┐             │
│  │  llama.cpp    │  │   Qdrant     │             │
│  │  Gemma 4 E4B │  │  (RAG/Memory)│             │
│  └──────┬───────┘  └──────┬───────┘             │
│         │                 │                      │
│  ┌──────▼────────────────▼───────┐              │
│  │     Python Orchestrator       │              │
│  │  (GTD briefing, session mgmt) │              │
│  └──────┬────────────────┬───────┘              │
│         │                │                      │
│  ┌──────▼──────┐  ┌─────▼────────┐             │
│  │    Redis     │  │  Open WebUI  │             │
│  │ (session st) │  │  (fallback)  │             │
│  └─────────────┘  └──────────────┘              │
└─────────────────────────────────────────────────┘
         ▲                    ▲
    ┌────┴────┐          ┌───┴───────┐
    │  iPhone  │          │   Browser │
    │ TimeBeam │          │   PWA     │
    │  (Swift) │          │           │
    └──────────┘          └───────────┘
   Tailscale              Tailscale
```

## Data Sources

- Gmail (email briefing)
- GitHub Projects (task tracking)
- iCal (.ics URL polling)

## Voice

- Input: IndicWhisper (Malayalam + English)
- Output: Indic Parler-TTS

## LLM Strategy

- **Primary**: Gemma 4 E4B via llama.cpp on Pi 5
- **Auto-sleep**: systemd socket activation (idle unload)
- **Fallback**: Qwen3-27B on GPUHub RTX 5090 via Tailscale

## Pi 5 Services

- llama.cpp (Gemma 4 E4B)
- Qdrant (long-term memory/RAG)
- Redis (session state)
- Open WebUI (fallback interface)

## Interfaces

- **Primary**: iOS Pomodoro app (TimeBeam, Swift) — connects via Tailscale
- **Fallback**: Open WebUI (PWA/browser)

## GitFlow Strategy

### Branch Structure

- `main` = production releases
- `develop` = active development branch
- `feature/*` = feature branches
- `archive/*` = archived code (old Spring Boot memory agent)

### Worktree Workflow

Feature development uses git worktrees for isolation:

```bash
git worktree add -b feature/my-feature ../worktrees/my-feature
```

## Kayis HQ Project

All issues tracked in GitHub Project #7 ("Kayis's HQ"):
- Labeled by repo: `synapse`, `time-beam`, `ironveil`, etc.
- Phases tracked via Milestone field
- Status workflow: Backlog → Planned → In Progress → Review → Done

## Conventions

### Backend (Python)

- FastAPI for HTTP API
- Pydantic for data models
- async/await throughout
- Configuration via `.env` + pydantic-settings

### Pi Deployment

- systemd services for all components
- docker-compose for Qdrant + Redis + Open WebUI
- llama.cpp as native binary (no container)
- Tailscale for network access

### Code Quality

- Type hints required
- Black formatting
- ruff linting
- pytest with async support
