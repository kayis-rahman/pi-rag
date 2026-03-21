#!/bin/bash
# Secondary Server Startup Script (gpuhub - Singapore)
# Model: Qwen3.5-9B-AWQ
# GPU: NVIDIA GeForce RTX 4080 32GB
# Role: Fast subagent model (claude-haiku-*)
# Thinking: disabled (instruct mode)
# URL: https://u425-twwp-6d5643db.singapore-b.gpuhub.com:8443
# Port: 6007 (different from primary 6006)

set -e

echo "Starting secondary vLLM server (Qwen3.5-9B-AWQ) on gpuhub..."

# Apply tool parser patch
SERVING_FILE="$(python -m pip show vllm | awk -F': ' '/^Location:/{print $2}')/vllm/entrypoints/openai/chat_completion/serving.py"
if grep -q "streamed_args_for_tool\[index\]$" "$SERVING_FILE"; then
    sed -i 's/actual_call = tool_parser\.streamed_args_for_tool\[index\]/actual_call = tool_parser.streamed_args_for_tool[index] if index < len(tool_parser.streamed_args_for_tool) else ""/g' "$SERVING_FILE"
    echo "Tool parser patch applied."
else
    echo "Tool parser patch already applied."
fi

# Performance optimizations
export VLLM_USE_FLASHINFER_MOE_FP16=1
export PYTORCH_ALLOC_CONF=expandable_segments:True

# Start vLLM server on port 6007
vllm serve /root/autodl-tmp/models/Qwen3.5-9B-AWQ \
    --host 0.0.0.0 \
    --port 6006 \
    --max-model-len 262144 \
    --gpu-memory-utilization 0.90 \
    --max-num-seqs 6 \
    --enable-prefix-caching \
    --served-model-name "claude-haiku-4-5-20251001" "claude-haiku-4-5" "claude-haiku-4-6" \
    "claude-sonnet-4-6" "claude-sonnet-4-5-20251022" "claude-sonnet-4-5" \
    --tool-call-parser qwen3_coder \
    --reasoning-parser qwen3 \
    --trust-remote-code \
    --enable-auto-tool-choice \
    --enable-chunked-prefill \
    --max-num-batched-tokens 32768 \
    --block-size 64 \
    --speculative-config '{"method":"qwen3_next_mtp","num_speculative_tokens":1}' \
    --override-generation-config '{"temperature": 0.7, "top_p": 0.8, "enable_thinking": false}'
