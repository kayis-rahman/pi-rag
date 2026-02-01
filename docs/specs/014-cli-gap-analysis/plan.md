# Feature 014 - CLI Gap Analysis & Missing Features: Technical Plan

**Feature ID**: 014-cli-gap-analysis  
**Status**: [In Progress]  
**Created**: February 1, 2026  
**Objective**: Implement missing CLI commands (ingest, query) and fix model path

---

## 🎯 Technical Approach

### Overview

This feature implements two missing CLI commands and fixes the model path configuration:

1. **Implement `synapse ingest`** - Call `scripts/bulk_ingest.py` as subprocess
2. **Implement `synapse query`** - Call MCP server API via HTTP
3. **Fix model path** - Use same configuration as MCP server

### Implementation Details

#### 1. Implement `synapse ingest`

**Approach**: Subprocess call to `scripts/bulk_ingest.py`

```python
@app.command()
def ingest(
    path: Path = typer.Argument(..., help="Path to ingest"),
    project_id: str = typer.Option("synapse", "--project-id", "-p"),
    file_type: List[str] = typer.Option(None, "--file-type", "-t"),
    exclude: List[str] = typer.Option(None, "--exclude", "-e"),
    chunk_size: Optional[int] = typer.Option(None, "--chunk-size"),
    dry_run: bool = typer.Option(False, "--dry-run"),
):
    """Ingest documents into SYNAPSE knowledge base."""
    cmd = ["python3", "-m", "scripts.bulk_ingest", "--root-dir", str(path)]
    if project_id:
        cmd.extend(["--project-id", project_id])
    if file_type:
        for ft in file_type:
            cmd.extend(["--file-type", ft])
    if exclude:
        for ex in exclude:
            cmd.extend(["--exclude", ex])
    if chunk_size:
        cmd.extend(["--chunk-size", str(chunk_size)])
    if dry_run:
        cmd.append("--dry-run")
    
    print(f"📄 Ingesting: {path}")
    subprocess.run(cmd)
```

#### 2. Implement `synapse query`

**Approach**: Call MCP server API via HTTP

```python
@app.command()
def query(
    text: str = typer.Argument(..., help="Query text"),
    top_k: Optional[int] = typer.Option(3, "--top-k", "-k"),
    format: str = typer.Option("json", "--format", "-f"),
):
    """Query SYNAPSE knowledge base."""
    # Call MCP endpoint
    import httpx
    response = httpx.post(
        "http://localhost:8002/mcp",
        json={
            "method": "tools/call",
            "params": {
                "name": "synapse.search",
                "arguments": {
                    "project_id": "synapse",
                    "query": text,
                    "top_k": top_k
                }
            }
        }
    )
    # Format and display results
```

#### 3. Fix Model Path

**Approach**: Use configuration from MCP server

```python
# In synapse/config.py
def get_model_path():
    """Get model path from shared configuration."""
    # Check multiple locations
    paths = [
        Path.home() / ".synapse" / "models",
        Path("/opt/synapse/models"),
        Path.cwd() / "models",
    ]
    for path in paths:
        if path.exists():
            return str(path)
    return str(paths[0])  # Default to ~/.synapse/models
```

---

## Files to Modify

| File | Change |
|------|--------|
| `synapse/cli/main.py` | Implement `ingest()` and `query()` functions |
| `synapse/config.py` | Ensure model path matches MCP server |
| `rag/embedding.py` | Fix hardcoded model path |

---

## Risk Assessment

### Low Risk
- **Risk**: Subprocess call fails
- **Mitigation**: Add error handling
- **Impact**: Minor, easy to fix

### Medium Risk  
- **Risk**: MCP server not running for query
- **Mitigation**: Check server status first, show helpful error
- **Impact**: Command fails with clear message

### Low Risk
- **Risk**: Model path fix breaks MCP
- **Mitigation**: Test on dev branch first
- **Impact**: Easy to revert

---

## Testing Strategy

### Manual Testing

| Test | Command | Expected Result |
|------|---------|-----------------|
| Test ingest | `synapse ingest .` | Files ingested |
| Test query | `synapse query "test"` | Results returned |
| Test model path | Check logs | No mock warnings |
| Test options | `synapse ingest . --dry-run` | Preview mode |

### Automated Testing (Future)
- Add to Feature 001 test suite
- Mock MCP server for query tests
- Mock file system for ingest tests

---

## Implementation Phases

### Phase 1: Analysis (15 min)
1. Analyze MCP server for model path resolution
2. Document current model path configuration
3. Plan model path fix

### Phase 2: Implement Ingest (45 min)
4. Update `synapse/cli/main.py` ingest function
5. Add subprocess call to bulk_ingest.py
6. Test ingest command

### Phase 3: Implement Query (45 min)
7. Update `synapse/cli/main.py` query function
8. Add HTTP call to MCP server
9. Test query command

### Phase 4: Fix Model Path (30 min)
10. Update `synapse/config.py` model path
11. Update `rag/ingestion.py` if needed
12. Verify no mock warnings

### Phase 5: Validation (15 min)
13. Test all CLI commands
14. Update documentation
15. Commit and push

---

## Success Criteria

### Must Have
- [ ] All 10 CLI commands working
- [ ] `synapse ingest .` works
- [ ] `synapse query "text"` works
- [ ] No mock embedding warnings

### Should Have
- [ ] Progress output during ingestion
- [ ] Clear error messages
- [ ] Documentation accurate

### Nice to Have
- [ ] Progress bar during ingestion
- [ ] Colored output

---

## Timeline

| Phase | Duration | Tasks | Deliverables |
|-------|----------|-------|--------------|
| Phase 1 | 15 min | 3 | Analysis complete |
| Phase 2 | 45 min | 3 | Ingest working |
| Phase 3 | 45 min | 3 | Query working |
| Phase 4 | 30 min | 3 | Model path fixed |
| Phase 5 | 15 min | 3 | Validated & pushed |
| **Total** | **~2.5 hrs** | **15** | **Complete CLI** |

---

**Plan Created**: February 1, 2026  
**Status**: Ready for Implementation  
**Next**: Create tasks.md
