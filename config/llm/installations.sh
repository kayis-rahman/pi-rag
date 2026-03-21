#!/bin/bash
# Fresh instance setup for vLLM + Qwen3.5-35B-A3B-AWQ
# Tested on: CUDA 12.8, Python 3.12, Ubuntu 22.04

# ── 1. Install vLLM nightly ──────────────────────────────────────────
pip install -U vllm --pre \
  --index-url https://pypi.org/simple \
  --extra-index-url https://wheels.vllm.ai/nightly

# ── 2. Clear flashinfer cache (prevents ninja build errors) ──────────
rm -rf ~/.cache/flashinfer

# ── 3. Install correct transformers version ──────────────────────────
pip install -U "transformers @ git+https://github.com/huggingface/transformers.git@f2ba019"

# ── 4. Fix RoPE bug in transformers ──────────────────────────────────
TF_FILE="$(python -m pip show transformers | awk -F': ' '/^Location:/{print $2}')/transformers/modeling_rope_utils.py"
echo "Patching: $TF_FILE"
NEW_LINE='            ignore_keys_at_rope_validation = set(ignore_keys_at_rope_validation) | {"partial_rotary_factor"}' \
perl -i.bak -pe 'if ($. == 651) { $_ = $ENV{NEW_LINE} . "\n" }' "$TF_FILE"

# ── 5. Fix tool parser streaming bug ─────────────────────────────────
SERVING_FILE="$(python -m pip show vllm | awk -F': ' '/^Location:/{print $2}')/vllm/entrypoints/openai/chat_completion/serving.py"
echo "Patching: $SERVING_FILE"
sed -i 's/actual_call = tool_parser\.streamed_args_for_tool\[index\]/actual_call = tool_parser.streamed_args_for_tool[index] if index < len(tool_parser.streamed_args_for_tool) else ""/g' "$SERVING_FILE"

# ── 6. Write MoE config for RTX 4080 ─────────────────────────────────
MOE_CONFIG_DIR="$(python -m pip show vllm | awk -F': ' '/^Location:/{print $2}')/vllm/model_executor/layers/fused_moe/configs"
cat > "${MOE_CONFIG_DIR}/E=256,N=512,device_name=NVIDIA_GeForce_RTX_4080.json" << 'EOF'
{
    "1": {"BLOCK_SIZE_M": 16, "BLOCK_SIZE_N": 32, "BLOCK_SIZE_K": 64, "GROUP_SIZE_M": 1, "num_warps": 4, "num_stages": 3},
    "2": {"BLOCK_SIZE_M": 16, "BLOCK_SIZE_N": 32, "BLOCK_SIZE_K": 64, "GROUP_SIZE_M": 1, "num_warps": 4, "num_stages": 3},
    "4": {"BLOCK_SIZE_M": 16, "BLOCK_SIZE_N": 64, "BLOCK_SIZE_K": 64, "GROUP_SIZE_M": 1, "num_warps": 4, "num_stages": 3},
    "8": {"BLOCK_SIZE_M": 16, "BLOCK_SIZE_N": 128, "BLOCK_SIZE_K": 128, "GROUP_SIZE_M": 1, "num_warps": 8, "num_stages": 3},
    "16": {"BLOCK_SIZE_M": 16, "BLOCK_SIZE_N": 64, "BLOCK_SIZE_K": 64, "GROUP_SIZE_M": 32, "num_warps": 4, "num_stages": 4},
    "24": {"BLOCK_SIZE_M": 16, "BLOCK_SIZE_N": 64, "BLOCK_SIZE_K": 128, "GROUP_SIZE_M": 1, "num_warps": 8, "num_stages": 2},
    "32": {"BLOCK_SIZE_M": 16, "BLOCK_SIZE_N": 64, "BLOCK_SIZE_K": 128, "GROUP_SIZE_M": 1, "num_warps": 4, "num_stages": 2},
    "48": {"BLOCK_SIZE_M": 16, "BLOCK_SIZE_N": 64, "BLOCK_SIZE_K": 128, "GROUP_SIZE_M": 32, "num_warps": 4, "num_stages": 2},
    "64": {"BLOCK_SIZE_M": 16, "BLOCK_SIZE_N": 64, "BLOCK_SIZE_K": 128, "GROUP_SIZE_M": 1, "num_warps": 4, "num_stages": 2},
    "96": {"BLOCK_SIZE_M": 32, "BLOCK_SIZE_N": 128, "BLOCK_SIZE_K": 128, "GROUP_SIZE_M": 1, "num_warps": 8, "num_stages": 3},
    "128": {"BLOCK_SIZE_M": 64, "BLOCK_SIZE_N": 128, "BLOCK_SIZE_K": 128, "GROUP_SIZE_M": 1, "num_warps": 8, "num_stages": 2},
    "256": {"BLOCK_SIZE_M": 64, "BLOCK_SIZE_N": 128, "BLOCK_SIZE_K": 128, "GROUP_SIZE_M": 1, "num_warps": 8, "num_stages": 2},
    "512": {"BLOCK_SIZE_M": 64, "BLOCK_SIZE_N": 128, "BLOCK_SIZE_K": 128, "GROUP_SIZE_M": 1, "num_warps": 8, "num_stages": 3},
    "1024": {"BLOCK_SIZE_M": 64, "BLOCK_SIZE_N": 128, "BLOCK_SIZE_K": 64, "GROUP_SIZE_M": 1, "num_warps": 4, "num_stages": 3},
    "1536": {"BLOCK_SIZE_M": 64, "BLOCK_SIZE_N": 128, "BLOCK_SIZE_K": 64, "GROUP_SIZE_M": 1, "num_warps": 4, "num_stages": 3},
    "2048": {"BLOCK_SIZE_M": 128, "BLOCK_SIZE_N": 128, "BLOCK_SIZE_K": 64, "GROUP_SIZE_M": 16, "num_warps": 8, "num_stages": 3},
    "3072": {"BLOCK_SIZE_M": 128, "BLOCK_SIZE_N": 256, "BLOCK_SIZE_K": 64, "GROUP_SIZE_M": 1, "num_warps": 8, "num_stages": 3},
    "4096": {"BLOCK_SIZE_M": 128, "BLOCK_SIZE_N": 256, "BLOCK_SIZE_K": 64, "GROUP_SIZE_M": 16, "num_warps": 8, "num_stages": 3}
}
EOF
echo "MoE config written."

# ── 7. Download model ─────────────────────────────────────────────────
# For 35B (primary instance):
huggingface-cli download Qwen/Qwen3.5-35B-A3B-AWQ \
  --local-dir /root/autodl-tmp/models/Qwen3.5-35B-A3B-AWQ

# For 9B (secondary instance, uncomment if needed):
# huggingface-cli download QuantTrio/Qwen3.5-9B-AWQ \
#   --local-dir /workspace/models/Qwen3.5-9B-AWQ

echo "Installation complete. Run start_vllm.sh to start the server."