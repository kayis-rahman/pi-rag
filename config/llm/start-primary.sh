#!/bin/bash
# Primary Server Startup Script (gpuhub - Singapore)
# Model: Qwen3.5-35B-A3B-AWQ (MoE, 3B activated parameters)
# GPU: NVIDIA GeForce RTX 4080 32GB

set -e

echo "Starting primary vLLM server on gpuhub..."

# Performance optimizations
export VLLM_USE_DEEP_GEMM=0
export VLLM_USE_FLASHINFER_MOE_FP16=1
export VLLM_USE_FLASHINFER_SAMPLER=0
export PYTORCH_ALLOC_CONF=expandable_segments:True

# Apply MoE config for RTX 4080 if not already present
MOE_CONFIG_PATH="/root/miniconda3/lib/python3.12/site-packages/vllm/model_executor/layers/fused_moe/configs/E=256,N=512,device_name=NVIDIA_GeForce_RTX_4080.json"
if [ ! -f "$MOE_CONFIG_PATH" ]; then
    echo "WARNING: MoE config not found at $MOE_CONFIG_PATH - may need to reapply after vLLM upgrade"
fi

# Start vLLM server
taskset -c 0-7 vllm serve /root/autodl-tmp/models/Qwen3.5-35B-A3B-AWQ \
    --host 0.0.0.0 \
    --port 6006 \
    --max-model-len 229376 \
    --gpu-memory-utilization 0.95 \
    --max-num-seqs 4 \
    --enable-prefix-caching \
    --served-model-name "claude-sonnet-4-6" "claude-sonnet-4-5-20251022" "claude-sonnet-4-5" \
    --tool-call-parser qwen3_coder \
    --reasoning-parser qwen3 \
    --trust-remote-code \
    --enable-auto-tool-choice \
    --swap-space 8 \
    --enable-chunked-prefill \
    --max-num-batched-tokens 32768 \
    --block-size 64 \
    --override-generation-config '{"temperature": 0.6, "top_p": 0.95}' \
    --speculative-config '{"method":"mtp","num_speculative_tokens":1}'
