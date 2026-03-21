#!/bin/bash
# LiteLLM Proxy Server Startup Script
# Router: Mac M1 - localhost

set -e

echo "Starting LiteLLM proxy server..."

# Get the absolute path to the config file
CONFIG_FILE="$(cd "$(dirname "$0")" && pwd)/litellm_config.yaml"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file not found at $CONFIG_FILE"
    exit 1
fi

# Update Vast.ai IP if placeholder still present
if grep -q "<VAST_AI_IP>" "$CONFIG_FILE"; then
    echo "WARNING: Please update Vast.ai IP in litellm_config.yaml"
    echo "Edit the file and replace <VAST_AI_IP> with your actual Vast.ai IP address"
fi

# Start LiteLLM proxy
litellm --config "$CONFIG_FILE" --port 6006 --host 0.0.0.0
