# Synapse Orchestrator

Personal AI assistant hub — GTD briefing + focus sessions.

## Quick Start

```bash
# Setup
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Run
uvicorn app.main:app --reload --host 0.0.0.0 --port 8080
```

## Architecture

- **FastAPI** — HTTP API layer
- **llama.cpp** — Local LLM (Gemma 4 E4B)
- **Qdrant** — Vector memory/RAG
- **Redis** — Session state
- **Open WebUI** — Fallback interface

## Project Structure

```
synapse/
├── app/
│   ├── main.py           # FastAPI entry point
│   ├── config.py         # Settings (pydantic-settings)
│   ├── api/              # Route handlers (placeholder)
│   ├── services/         # Business logic (placeholder)
│   ├── models/           # Pydantic data models (placeholder)
│   └── infra/            # Infrastructure clients (placeholder)
├── systemd/              # systemd service + deployment scripts
│   ├── synapse.service   # Systemd unit for orchestrator
│   └── synapse.automator.sh  # One-shot Pi setup script
├── tests/                # pytest
├── docker-compose.yml    # Qdrant + Redis + Open WebUI
├── requirements.txt      # Python dependencies
└── .env.example          # Environment template
```
