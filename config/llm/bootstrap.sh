pkill -f vllm
sleep 5

# Coder on 6006 (internal)
taskset -c 0-7 vllm serve /root/autodl-tmp/models/Qwen3-Coder-30B-AWQ \
  --host 127.0.0.1 \
  --port 6006 \
  --max_model_len 71936 \
  --gpu_memory_utilization 0.72 \
  --max_num_seqs 2 \
  --enable_prefix_caching \
  --served_model_name "claude-sonnet-4-5-20251022" \
  --tool-call-parser qwen3_coder \
  --trust-remote-code \
  --enable-auto-tool-choice \
  --swap-space 8 &

sleep 60
nvidia-smi

# Embedding on 8080 (internal)
vllm serve /root/autodl-tmp/models/boboliu/Qwen3-Embedding-4B-W4A16-G128 \
  --host 127.0.0.1 \
  --port 8080 \
  --gpu_memory_utilization 0.15 \
  --runner pooling \
  --served_model_name "qwen-embedding" \
  --trust-remote-code \
  --max_model_len 8192 &

sleep 30

# Reranker on 8081 (internal)
vllm serve /root/autodl-tmp/models/boboliu/Qwen3-Reranker-4B-W4A16-G128 \
  --host 127.0.0.1 \
  --port 8081 \
  --gpu_memory_utilization 0.08 \
  --runner pooling \
  --served_model_name "qwen-reranker" \
  --trust-remote-code \
  --max_model_len 8192 &