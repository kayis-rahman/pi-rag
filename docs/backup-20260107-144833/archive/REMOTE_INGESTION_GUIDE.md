# Remote File Ingestion Guide

## Overview

The `core.ingest_file` MCP tool now supports **remote file uploads** from any machine (Mac, Windows, Linux).

## How It Works

1. **Upload Phase**: Upload file to server's upload directory
2. **Ingestion Phase**: Call `core.ingest_file` with full absolute path
3. **Validation Phase**: Server validates path and reads file
4. **Processing Phase**: File is ingested into semantic memory
5. **Cleanup Phase**: Old files automatically removed (after 1 hour)

## Upload Directory

**Default**: `/tmp/rag-uploads`

**Configurable via**:
- Environment variable: `RAG_UPLOAD_DIR`
- Config file: `configs/rag_config.json` → `remote_upload_directory`

## Configuration

### Config File (`configs/rag_config.json`)

```json
{
  "remote_file_upload_enabled": true,
  "remote_upload_directory": "/tmp/rag-uploads",
  "remote_upload_max_age_seconds": 3600,
  "remote_upload_max_file_size_mb": 50
}
```

### Environment Variables

```bash
# Enable/disable remote uploads
export RAG_REMOTE_UPLOAD_ENABLED=true

# Set upload directory
export RAG_UPLOAD_DIR=/tmp/rag-uploads

# Set maximum file age before cleanup (seconds)
export RAG_UPLOAD_MAX_AGE=3600

# Set maximum file size (MB)
export RAG_UPLOAD_MAX_SIZE=50
```

## Usage Examples

### From Mac Client (Recommended)

```bash
# Step 1: Upload file to server's upload directory
scp my-project/README.md dietpi@pi-ip:/tmp/rag-uploads/

# Step 2: Call ingest tool via MCP
# Your MCP client will provide the path:
{
  "project_id": "my-project",
  "file_path": "/tmp/rag-uploads/README.md",
  "source_type": "file"
}
```

### From Windows Client (PowerShell)

```powershell
# Step 1: Upload file to server
scp my-project\README.md dietpi@pi-ip:/tmp/rag-uploads/

# Step 2: Call ingest tool via MCP
# Your MCP client will provide the path:
@{
  "project_id": "my-project",
  "file_path": "/tmp/rag-uploads/README.md",
  "source_type": "file"
}
```

### From Local (on Pi)

```bash
# Step 1: Copy file to upload directory
cp my-project/README.md /tmp/rag-uploads/

# Step 2: Call ingest tool via MCP
{
  "project_id": "my-project",
  "file_path": "/tmp/rag-uploads/README.md",
  "source_type": "file"
}
```

### From Different Directories

```bash
# Upload from anywhere on your filesystem
scp /path/to/anywhere/file.py dietpi@pi-ip:/tmp/rag-uploads/

# Ingest with absolute path
{
  "project_id": "my-project",
  "file_path": "/tmp/rag-uploads/file.py",
  "source_type": "code"
}
```

## Validation Rules

### Path Validation

✅ **Allowed**:
- File must exist within upload directory (`/tmp/rag-uploads/`)
- File path must be absolute
- File must be readable

❌ **Blocked**:
- File path outside upload directory
- Symlink attacks (detected via `realpath()`)
- Path traversal attempts (`../`, `..`)
- Files that don't exist

### File Size Limits

- **Default**: 50 MB maximum
- **Configurable**: Via `RAG_UPLOAD_MAX_SIZE` environment variable
- **Error**: "File too large: {size}MB (max: {limit}MB)"

### File Age Limits

- **Default**: Files older than 1 hour are automatically deleted
- **Configurable**: Via `RAG_UPLOAD_MAX_AGE` environment variable
- **Purpose**: Prevent disk bloat

## Security Features

### 1. Allowlist-Based Directory
- Only files in designated upload directory are allowed
- Cannot access files elsewhere on server

### 2. Realpath Validation
- Prevents symlink attacks
- Detects attempts to escape upload directory

### 3. Permission Checks
- Ensures file is readable by server
- Returns clear error if not

### 4. Size Limits
- Prevents abuse with large files
- Configurable limit (default: 50MB)

### 5. Automatic Cleanup
- Removes old uploaded files
- Prevents disk space exhaustion

## Error Handling

### File Not Found

```json
{
  "status": "error",
  "error": "File not found: /tmp/rag-uploads/README.md",
  "message": "File validation failed: File not found"
}
```

**Solution**: Ensure file is uploaded before calling ingest tool.

### Path Outside Upload Directory

```json
{
  "status": "error",
  "error": "File path must be within upload directory: /tmp/rag-uploads",
  "message": "File validation failed: File path must be within upload directory"
}
```

**Solution**: Use absolute path within `/tmp/rag-uploads/`.

### File Too Large

```json
{
  "status": "error",
  "error": "File too large: 75.5MB (max: 50MB)",
  "message": "File validation failed: File too large"
}
```

**Solution**: Use smaller file or increase `RAG_UPLOAD_MAX_SIZE`.

### Remote Upload Disabled

```json
{
  "status": "error",
  "error": "Remote file upload is disabled",
  "message": "File validation failed: Remote file upload is disabled"
}
```

**Solution**: Set `RAG_REMOTE_UPLOAD_ENABLED=true` in environment.

## Token Optimization

### Problem (Before)

When uploading file content directly:
1. **Client**: Reads entire file into memory
2. **Client**: Pastes content into MCP tool call
3. **Server**: Parses content from prompt

**Token Cost**:
- File: 1MB ≈ 1,400,000 characters ≈ 525,000 tokens
- MCP protocol overhead: ~2,000 tokens
- **Total**: ~527,000 tokens per file upload

### Solution (After)

When uploading via path:
1. **Client**: Uploads file to server directory (token cost: 0)
2. **Client**: Provides file path to MCP tool (20-50 tokens)
3. **Server**: Reads file from disk (token cost: 0)

**Token Cost**:
- File path: 20-50 tokens
- MCP protocol overhead: ~2,000 tokens
- **Total**: ~2,050 tokens per file upload

### Savings

**Token Reduction**: **99.6%** (527,000 → 2,050 tokens)

**Benefits**:
1. Dramatically reduce AI token usage
2. Faster MCP calls (no large content in prompt)
3. Support larger files (no prompt size limits)
4. Better for binary files (no base64 encoding in prompt)

## Real-World Example

### Scenario: Upload README.md from Mac to Pi

```bash
# On Mac:
cd my-project

# Upload file to Pi
scp README.md dietpi@192.168.1.100:/tmp/rag-uploads/

# Call MCP tool (via your MCP client)
# This sends:
{
  "project_id": "my-project",
  "file_path": "/tmp/rag-uploads/README.md",
  "source_type": "file"
}

# Server response:
{
  "status": "success",
  "file_path": "/tmp/rag-uploads/README.md",
  "real_path": "/tmp/rag-uploads/README.md",
  "chunk_count": 42,
  "doc_id": "doc-12345",
  "message": "Successfully ingested 42 chunk(s)",
  "upload_config": {
    "enabled": true,
    "directory": "/tmp/rag-uploads",
    "max_size_mb": 50
  }
}
```

## Troubleshooting

### Issue: "File not found" error

**Checklist**:
- [ ] File uploaded to correct directory
- [ ] File name matches exactly
- [ ] File permissions allow reading

**Debug**:
```bash
# On server (Pi):
ls -la /tmp/rag-uploads/
```

### Issue: "Path outside upload directory" error

**Checklist**:
- [ ] Using absolute path
- [ ] Path starts with `/tmp/rag-uploads/`
- [ ] No `..` or `../` in path

**Debug**:
```bash
# Check path is absolute and normalized
realpath /tmp/rag-uploads/file.md
```

### Issue: Upload directory doesn't exist

**Solution**: Server creates it automatically

```bash
# The server will create it on first ingest call
# No manual action needed
```

### Issue: File permissions error

**Checklist**:
- [ ] File is readable (`chmod 644` or similar)
- [ ] Directory permissions allow reading (`chmod 755`)

## Best Practices

### 1. Upload Files First

Always upload files before calling `core.ingest_file`:
```bash
# ✅ Good
scp file.md pi:/tmp/rag-uploads/ && call_mcp_tool

# ❌ Bad
call_mcp_tool && scp file.md pi:/tmp/rag-uploads/
```

### 2. Use Absolute Paths

Always provide full absolute paths:
```json
{
  "file_path": "/tmp/rag-uploads/README.md"  // ✅ Absolute
}
```

Not:
```json
{
  "file_path": "README.md"  // ❌ Relative
}
```

### 3. Check File Size Before Upload

Avoid errors by checking size:
```bash
# Check file size
ls -lh README.md

# If too large, compress or split
# (max size default: 50MB)
```

### 4. Use Appropriate Source Type

Choose correct source type:
```json
{
  "source_type": "file"   // Documentation, markdown, text files
  "source_type": "code"   // Python, JavaScript, Go, etc.
  "source_type": "web"    // Articles, blogs, web content
}
```

## Advanced Usage

### Batch Uploads

Upload multiple files then ingest:
```bash
# Upload all files
scp docs/* dietpi@pi-ip:/tmp/rag-uploads/

# Ingest each file
for file in docs/*; do
    # Call rag.ingest_file for each
    mcp_call "rag.ingest_file" "{\"project_id\":\"my\",\"file_path\":\"/tmp/rag-uploads/$file\"}"
done
```

### Custom Upload Directory

Change upload directory for different projects:
```bash
# For project A
export RAG_UPLOAD_DIR=/tmp/rag-uploads/project-a
scp project-a/* pi:/tmp/rag-uploads/project-a/

# For project B
export RAG_UPLOAD_DIR=/tmp/rag-uploads/project-b
scp project-b/* pi:/tmp/rag-uploads/project-b/
```

## Summary

### Key Features

✅ **Remote-Friendly**: Upload from any machine
✅ **Token Optimized**: 99.6% reduction in tokens
✅ **Secure**: Allowlist-based, validation, cleanup
✅ **Configurable**: Environment variables and config file
✅ **Backward Compatible**: Existing local ingestion still works
✅ **Cross-Platform**: Works on Mac, Windows, Linux

### Benefits

1. **Massive Token Savings**: 99.6% reduction per file upload
2. **No Prompt Size Limits**: Files limited only by disk, not tokens
3. **Faster**: Smaller MCP tool calls
4. **Better for Binary Files**: No base64 in prompts
5. **Scalable**: Works with any file size (within limits)
6. **Secure**: Multiple validation layers

### Comparison: Before vs After

| Aspect | Before (Content Upload) | After (Path Upload) |
|---------|----------------------|-------------------|
| **Token Usage** | ~527,000 tokens | ~2,050 tokens |
| **File Size Limit** | Prompt size (~100KB) | Disk size (50MB) |
| **Binary Support** | No (needs encoding) | Yes |
| **Security** | Basic | Multi-layer |
| **Error Clarity** | Vague | Specific |
| **Debugging** | Hard (in prompt) | Easy (file on disk) |
| **Savings** | N/A | **99.6%** |

---

## Quick Reference

### Upload Command

```bash
# From Mac/Linux
scp <local-file> <user>@<host>:/tmp/rag-uploads/

# From Windows (PowerShell)
scp <local-file> <user>@<host>:/tmp/rag-uploads/
```

### MCP Tool Call

```json
{
  "name": "rag.ingest_file",
  "arguments": {
    "project_id": "your-project-id",
    "file_path": "/tmp/rag-uploads/your-file.md",
    "source_type": "file"
  }
}
```

### Environment Variables

```bash
export RAG_UPLOAD_DIR=/tmp/rag-uploads
export RAG_REMOTE_UPLOAD_ENABLED=true
export RAG_UPLOAD_MAX_AGE=3600
export RAG_UPLOAD_MAX_SIZE=50
```

---

**Ready for remote file ingestion!** 🚀
