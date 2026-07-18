#!/usr/bin/env bash
# Install Synapse orchestrator on Pi 5 — creates venv, installs deps, enables systemd service.
set -euo pipefail

REPO_DIR="$HOME/workspace/ideas/synapse"
VENV="$REPO_DIR/.venv"

# Create virtual environment
if [[ ! -d "$VENV" ]]; then
    python3 -m venv "$VENV"
fi

source "$VENV/bin/activate"
pip install -r "$REPO_DIR/requirements.txt" -q

# Enable systemd service
sudo systemctl daemon-reload
sudo systemctl enable synapse.service
sudo systemctl start synapse.service

echo "Synapse orchestrator started."