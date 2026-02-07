# Embedding Model Compatibility Issue

**Date**: 2026-02-07
**Issue**: BGE-M3 model crashes during ingestion
**Status**: Documented workaround available

## Problem

The BGE-M3 embedding model (`bge-m3-q8_0.gguf`, 589MB) crashes with a C++ `std::out_of_range` exception in the tokenizer when processing real-world file content.

### Error Details
```
terminate called after throwing an instance of 'std::out_of_range'
  what():  unordered_map::at
```

Location: `llama_vocab::byte_to_token` during tokenization

## Investigation Results

### Attempted Fixes
1. ✅ Enhanced content sanitization in `_generate_embedding()`
2. ✅ Clean reinstall of llama-cpp-python 0.3.16 (latest)
3. ✅ Force rebuild without cache

### Test Results
- **Simple text**: ✅ Works (1024 dimensions)
- **Real file content**: ❌ Crashes consistently

### Root Cause Analysis
The BGE-M3 model has a fundamental compatibility issue with certain byte sequences present in real-world files. The crashes occur at the C++ level in the tokenizer, making them uncatchable by Python exception handling.

## Recommended Solution

### Use bge-small-en-v1.5-q8_0.gguf

**Location**: `~/.synapse/models/bge-small-en-v1.5-q8_0.gguf`
**Size**: 35MB (vs 589MB for BGE-M3)
**Dimensions**: 384 (vs 1024 for BGE-M3)
**Status**: ✅ Proven working, no crashes

### Configuration Update

Update `configs/rag_config.json`:
```json
{
  "embedding_model_path": "~/.synapse/models/bge-small-en-v1.5-q8_0.gguf"
}
```

### Verification

Test the working model:
```python
from llama_cpp import Llama

model = Llama(
    model_path="~/.synapse/models/bge-small-en-v1.5-q8_0.gguf",
    embedding=True,
    verbose=False,
    n_ctx=512
)

embedding = model.embed("Test content")
print(f"✓ Success: {len(embedding)} dimensions")  # Output: 384
```

## Trade-offs

| Feature | BGE-M3 (Broken) | bge-small (Working) |
|---------|----------------|---------------------|
| Dimensions | 1024 | 384 |
| Model Size | 589MB | 35MB |
| Speed | Slower | Faster |
| Quality | Theoretically better | Good for RAG |
| Stability | ❌ Crashes | ✅ Stable |

## Conclusion

While BGE-M3 offers higher dimensionality (1024 vs 384), the bge-small-en-v1.5 model provides:
- ✅ Reliable operation without crashes
- ✅ Faster ingestion (smaller model)
- ✅ Sufficient quality for RAG applications
- ✅ 17x smaller disk footprint

**Recommendation**: Use bge-small-en-v1.5-q8_0.gguf for production ingestion.

## Related Files

- `configs/rag_config.json` - Model path configuration
- `rag/semantic_store.py` - Embedding generation with sanitization
- `docs/specs/015-ingestion-persistence/` - Original bug fix documentation

## Future Work

If higher dimensionality is needed:
1. Try different BGE-M3 GGUF variants (Q4_K_M, Q5_K_M, etc.)
2. Test with Python 3.11 or 3.12 (avoid 3.13)
3. Try nomic-embed-text or other embedding models
4. Download fresh BGE-M3 from official HuggingFace source

---

**Last Updated**: 2026-02-07
**Documented by**: Development Team
