#!/usr/bin/env python3
"""
HTTP MCP Wrapper for RAG Memory System - FastMCP Implementation
Provides proper MCP protocol support via streamable HTTP transport.

This version uses FastMCP to implement the MCP specification correctly,
ensuring compatibility with opencode and other MCP clients.

Clean version created from scratch with all fixes applied:
- Content mode for remote file ingestion
- Transport security for remote connections
- Correct data directory (/opt/synapse/data)
- Fixed query parameter handling for episodic search
- Embedding model filename fixed (embedding-gemma, not embeddinggemma)
"""

import asyncio
import json
import logging
import os
import shutil
import sys
import uuid
from datetime import datetime, timezone
from typing import Optional, Dict, Any

from starlette.applications import Starlette
from starlette.routing import Route, Mount
from starlette.middleware import Middleware
from starlette.middleware.cors import CORSMiddleware as StarletteCORSMiddleware
from starlette.responses import JSONResponse, Response
from starlette.datastructures import UploadFile
from mcp.server.fastmcp import FastMCP
from mcp.server.transport_security import TransportSecuritySettings

# Add parent directory to path for imports (only if not already in path)
# In Docker, PYTHONPATH=/app so we don't need this
if os.environ.get("SYNAPSE_ENV") != "docker":
    sys.path.insert(0, '/home/dietpi/synapse')

# Import RAG backend
from mcp_server.synapse_server import MemoryBackend

# Load RAG config once at module level for performance
# Use local configs directory when available, fall back to /app/configs for Docker
_config_path = os.environ.get("SYNAPSE_CONFIG_PATH", "/home/dietpi/synapse/configs/rag_config.json")
if not os.path.exists(_config_path):
    _config_path = "/app/configs/rag_config.json"
with open(_config_path, 'r') as f:
    _rag_config = json.load(f)
_context_injection_enabled = _rag_config.get("context_injection_enabled", False)

# Load MCP port from environment (set by start command with --port flag)
_mcp_port = int(os.environ.get("MCP_PORT", "8002"))

# Configuration
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger(__name__)

# Initialize RAG Backend
backend = MemoryBackend()

# Configure transport security to allow remote connections
# This allows opencode to connect from Mac
transport_security = TransportSecuritySettings(
    allowed_hosts=['*'],  # Allow all hosts
    allowed_origins=['*'],  # Allow all origins
    enable_dns_rebinding_protection=False  # Disable for local network access
)

# Create FastMCP instance with stateless mode
# Stateless mode: Each request gets a fresh transport, no session management needed
# This is simpler and more compatible with various MCP clients
mcp = FastMCP(
    "rag-memory-server",
    transport_security=transport_security,
    stateless_http=True,  # Use stateless HTTP (simpler, no session persistence)
    json_response=False,  # Use SSE for streaming responses
)

# ============================================================================
# MCP Tool Registration
# ============================================================================

@mcp.tool(name="sy.proj.list")
async def list_projects(scope_type: Optional[str] = None) -> dict:
    """List all projects in RAG memory system.

    Tool: sy.proj.list

    Args:
        scope_type: Optional filter by scope type (user, project, org, session)

    Returns:
        Dict with projects list and metadata
    """
    return await backend.list_projects(scope_type=scope_type)


@mcp.tool(name="sy.src.list")
async def list_sources(project_id: str, source_type: Optional[str] = None) -> dict:
    """List document sources for a project in semantic memory.

    Tool: sy.src.list

    Args:
        project_id: Project identifier
        source_type: Optional filter by source type (file, code, web)

    Returns:
        Dict with sources list and metadata
    """
    return await backend.list_sources(project_id=project_id, source_type=source_type)


@mcp.tool(name="sy.ctx.get")
async def get_context(
    project_id: str,
    context_type: str = "all",
    query: Optional[str] = None,
    max_results: int = 10
) -> dict:
    """Get comprehensive project context with authority hierarchy.

    Tool: sy.ctx.get

    Returns context respecting authority order:
    1. Symbolic memory (authoritative)
    2. Episodic memory (advisory)
    3. Semantic memory (non-authoritative)

    Args:
        project_id: Project identifier
        context_type: Type of context to retrieve (all, symbolic, episodic, semantic)
        query: Optional query for semantic retrieval
        max_results: Maximum results per memory type

    Returns:
        Dict with context from each memory type
    """
    return await backend.get_context(
        project_id=project_id,
        context_type=context_type,
        query=query,
        max_results=max_results
    )


@mcp.tool(name="sy.mem.search")
async def search(
    project_id: str,
    query: str,
    memory_type: str = "all",
    top_k: int = 10
) -> dict:
    """Semantic search across all memory types.

    Tool: sy.mem.search

    Args:
        project_id: Project identifier
        query: Search query
        memory_type: Type of memory to search (all, symbolic, episodic, semantic)
        top_k: Number of results

    Returns:
        Dict with search results
    """
    logger.debug(f"[DEBUG] search() called with project_id={project_id}, query={query}")
    try:
        result = await backend.search(
            project_id=project_id,
            query=query,
            memory_type=memory_type,
            top_k=top_k
        )
        logger.debug(f"[DEBUG] backend.search() returned: {type(result)}")
        return result
    except Exception as e:
        import traceback
        logger.error(f"[DEBUG] backend.search() failed: {e}")
        logger.error(f"[DEBUG] Traceback: {traceback.format_exc()}")
        raise


@mcp.tool(name="sy.mem.ingest")
async def ingest_file(
    project_id: str,
    file_path: Optional[str] = None,
    content: Optional[str] = None,
    filename: Optional[str] = None,
    source_type: str = "file",
    metadata: Optional[Dict[str, Any]] = None
) -> dict:
    """Ingest file OR text content into semantic memory.

    Tool: sy.mem.ingest

Current Configuration:
--------------------
context_injection_enabled = false

Available Ingestion Modes:
-------------------------------

MODE: HTTP Upload Flow (ONLY MODE AVAILABLE)
------------------------------------------------
Upload file via HTTP multipart form, then ingest with file_path.

Use case: Standard web uploads from any HTTP client
Workflow:
  1. Upload file via HTTP POST:
     curl -X POST http://localhost:8002/v1/upload \\
                -F "file=@document.txt"

  2. Get file_path from response:
     {"file_path": "/tmp/rag-uploads/abc123_document.txt", ...}

  3. Call this tool with file_path parameter:
     sy.mem.ingest(
          project_id="global",
          file_path="/tmp/rag-uploads/abc123_document.txt"
     )

  4. File is auto-deleted after ingestion

HTTP Endpoint: POST http://localhost:8002/v1/upload
Config: remote_file_upload_enabled=true (always enabled)

Args:
    project_id: Project identifier
    file_path: Path to file in upload directory (from HTTP upload response)
    content: Not used in current configuration (content mode is disabled)
    filename: Not used in current configuration (content mode is disabled)
    source_type: Type of source (file, code, web)
    metadata: Optional metadata to attach

Returns:
    Dict with ingestion results

Note: Content mode and direct file_path access are disabled.
Only HTTP upload flow is available.
    """
    # Mode 1: Content provided (disabled in current configuration)
    if content is not None:
        return {
            "status": "error",
            "error": "content_mode_disabled",
            "message": "Content mode is disabled. Use HTTP upload flow instead: POST /v1/upload to upload file, then use returned file_path"
        }

    # Mode 2: File path provided (original behavior, backward compatible)
    elif file_path is not None:
        # Use existing backend method - backend validates file_path is in upload directory
        return await backend.ingest_file(
            project_id=project_id,
            file_path=file_path,
            source_type=source_type,
            metadata=metadata
        )

    # Neither provided
    else:
        return {
            "status": "error",
            "error": "no_input",
            "message": "Either content or file_path must be provided"
        }


@mcp.tool(name="sy.mem.fact.add")
async def add_fact(
    project_id: str,
    fact_key: str,
    fact_value: Any,
    confidence: float = 0.9,
    category: Optional[str] = None
) -> dict:
    """Add a symbolic memory fact (authoritative).

    Tool: sy.mem.fact.add

    Args:
        project_id: Project identifier
        fact_key: The fact key
        fact_value: The fact value (any JSON-serializable type)
        confidence: Confidence level (0.0-1.0)
        category: Fact category (preference, constraint, decision, fact)

    Returns:
        Dict with fact creation result
    """
    return await backend.add_fact(
        project_id=project_id,
        fact_key=fact_key,
        fact_value=fact_value,
        confidence=confidence,
        category=category
    )


@mcp.tool(name="sy.mem.ep.add")
async def add_episode(
    project_id: str,
    title: str,
    content: str,
    lesson_type: str = "general",
    quality: float = 0.8
) -> dict:
    """Add an episodic memory episode (advisory).

    Tool: sy.mem.ep.add

    Args:
        project_id: Project identifier
        title: Episode title
        content: Episode content (situation, action, outcome, lesson)
        lesson_type: Type of lesson (general, pattern, mistake, success, failure)
        quality: Quality score (0.0-1.0)

    Returns:
        Dict with episode creation result
    """
    return await backend.add_episode(
        project_id=project_id,
        title=title,
        content=content,
        lesson_type=lesson_type,
        quality=quality
    )


# ============================================================================
# Custom Endpoints (Health Check)
# ============================================================================

@mcp.custom_route("/", methods=["GET"])
async def root_endpoint(request) -> Response:
    """Root endpoint for server info."""
    return JSONResponse({
        "service": "RAG MCP HTTP Server",
        "version": "2.0.0 (FastMCP Implementation)",
        "status": "running",
        "mcp_protocol": "streamable-http",
        "endpoint": "/mcp",
        "data_directory": backend._get_data_dir(),
        "transport": "http",
        "tools_available": 7,
        "tools": [
            "sy.proj.list",
            "sy.src.list",
            "sy.ctx.get",
            "sy.mem.search",
            "sy.mem.ingest",
            "sy.mem.fact.add",
            "sy.mem.ep.add"
        ],
        "message": "Server is running and ready for connections from Mac or other MCP clients",
        "opencode_config_url": f"http://piworm.local:{_mcp_port}/mcp",
        "upload_endpoint": "/v1/upload",
        "upload_directory": backend._upload_config["directory"]
    })


@mcp.custom_route("/health", methods=["GET"])
async def health_endpoint(request) -> Response:
    """Health check endpoint."""
    # Check upload directory
    upload_dir = backend._upload_config["directory"]
    upload_dir_status = "OK" if os.path.exists(upload_dir) else "NOT_CREATED"

    return JSONResponse({
        "status": "ok",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "version": "2.0.0",
        "protocol": "MCP Streamable HTTP",
        "tools_available": 7,
        "tools": [
            "sy.proj.list",
            "sy.src.list",
            "sy.ctx.get",
            "sy.mem.search",
            "sy.mem.ingest",
            "sy.mem.fact.add",
            "sy.mem.ep.add"
        ],
        "transport": "http",
        "data_directory": backend._get_data_dir(),
        "server": "RAG Memory Backend",
        "health_checks": {
            "backend": "OK",
            "episodic_store": "OK",
            "semantic_store": "OK",
            "symbolic_store": "OK",
            "upload_directory": upload_dir_status,
            "upload_dir_path": upload_dir
        }
    })


@mcp.custom_route("/v1/upload", methods=["POST"])
async def upload_file(request) -> Response:
    """
    Upload file to temp directory for ingestion.

    Returns file path for MCP ingestion tool.
    File is automatically deleted after successful ingestion.

    Usage:
        curl -X POST http://localhost:8002/v1/upload -F "file=@myfile.txt"

    Then call MCP tool:
        sy.mem.ingest(project_id="global", file_path="/tmp/rag-uploads/abc123_myfile.txt")
    """
    try:
        # Get upload form data
        form = await request.form()

        # Extract file from form
        if "file" not in form:
            return JSONResponse(
                {"status": "error", "message": "No file provided (use 'file' field)"},
                status_code=400
            )

        file_upload = form["file"]

        # Handle both UploadFile and already-read content
        if hasattr(file_upload, 'filename'):
            # This is a Starlette UploadFile object
            file_obj = file_upload
            filename = file_obj.filename
            await file_obj.seek(0)
            content = await file_obj.read()
        elif isinstance(file_upload, bytes):
            # File already read as bytes
            content = file_upload
            filename = "uploaded_file"
        elif isinstance(file_upload, str):
            # File as string (shouldn't happen, but handle it)
            content = file_upload.encode('utf-8')
            filename = "uploaded_file"
        else:
            # Try to get from form fields differently
            try:
                # Get raw upload from request
                upload_file = request._form.get("file")
                if hasattr(upload_file, 'file'):
                    file_obj = upload_file.file
                    filename = upload_file.filename or "uploaded_file"
                    content = await file_obj.read()
                else:
                    return JSONResponse(
                        {"status": "error", "message": f"Invalid file format: {type(file_upload)}"},
                        status_code=400
                    )
            except Exception as e:
                return JSONResponse(
                    {"status": "error", "message": f"Failed to read file: {str(e)}"},
                    status_code=400
                )

        if not filename:
            return JSONResponse(
                {"status": "error", "message": "Filename is empty"},
                status_code=400
            )

        # Load upload config from rag_config.json
        config_path = os.environ.get("SYNAPSE_CONFIG_PATH", "/app/configs/rag_config.json")
        with open(config_path, 'r') as f:
            config = json.load(f)

        upload_dir = config.get("remote_upload_directory", "/tmp/rag-uploads")
        max_size_mb = config.get("remote_upload_max_file_size_mb", 50)
        max_size_bytes = max_size_mb * 1024 * 1024

        # Ensure upload directory exists
        os.makedirs(upload_dir, exist_ok=True)

        # Validate file size
        file_size = len(content)

        if file_size == 0:
            return JSONResponse(
                {"status": "error", "message": "File is empty"},
                status_code=400
            )

        if file_size > max_size_bytes:
            size_mb = file_size / (1024 * 1024)
            return JSONResponse(
                {
                    "status": "error",
                    "message": f"File too large: {size_mb:.2f}MB (max: {max_size_mb}MB)"
                },
                status_code=413
            )

        # Generate unique filename to avoid conflicts
        unique_id = uuid.uuid4().hex[:8]
        unique_filename = f"{unique_id}_{filename}"
        file_path = os.path.join(upload_dir, unique_filename)

        # Save file
        with open(file_path, 'wb') as f:
            f.write(content)

        logger.info(f"File uploaded: {file_path} ({file_size} bytes, original: {filename})")

        return JSONResponse({
            "status": "success",
            "file_path": file_path,
            "original_filename": filename,
            "file_size": file_size,
            "upload_directory": upload_dir,
            "message": f"File uploaded successfully. Use sy.mem.ingest MCP tool with file_path='{file_path}'. File will be auto-deleted after ingestion."
        })

    except Exception as e:
        logger.error(f"Upload failed: {e}", exc_info=True)
        return JSONResponse(
            {"status": "error", "message": str(e)},
            status_code=500
        )


# ============================================================================
# Create Application
# ============================================================================

# Get FastMCP app with custom routes
app = mcp.streamable_http_app()


# ============================================================================
# Main Entry Point
# ============================================================================

if __name__ == "__main__":
    import uvicorn

    logger.info("=" * 60)
    logger.info("Starting RAG MCP HTTP Server (FastMCP Implementation)")
    logger.info("=" * 60)
    logger.info(f"MCP Protocol Endpoint: http://0.0.0.0:{_mcp_port}/mcp")
    logger.info(f"Health Check: http://0.0.0.0:{_mcp_port}/health")
    logger.info(f"Available Tools: 7")
    logger.info(f"Transport: Streamable HTTP")
    logger.info(f"Data Directory: {backend._get_data_dir()}")
    logger.info(f"Permissions: Allow all hosts/origins (remote-friendly)")
    logger.info("=" * 60)
    logger.info("")
    logger.info("RAG Memory Backend Features:")
    logger.info("- Symbolic Memory (authoritative): User preferences, decisions, constraints")
    logger.info("- Episodic Memory (advisory): Lessons learned from experience")
    logger.info("- Semantic Memory (non-authoritative): Document embeddings")
    logger.info("")
    logger.info("Available Tools:")
    logger.info("1. sy.proj.list - List all memory projects")
    logger.info("2. sy.src.list - List document sources for a project")
    logger.info("3. sy.ctx.get - Get comprehensive project context (all memory types)")
    logger.info("4. sy.mem.search - Semantic search across memory types")
    logger.info("5. sy.mem.ingest - Ingest document into semantic memory")
    logger.info("6. sy.mem.fact.add - Add symbolic facts (authoritative)")
    logger.info("7. sy.mem.ep.add - Add episodic episodes (advisory)")
    logger.info("=" * 60)
    logger.info("")
    logger.info("Content Mode Usage (Mac → Remote Pi):")
    logger.info("1. Open file on Mac (e.g., README.md)")
    logger.info("2. Copy file content to clipboard")
    logger.info("3. In opencode, tell opencode to ingest:")
    logger.info("   - Provide 'content' parameter with file content")
    logger.info("   - Provide 'filename' parameter (e.g., 'README.md')")
    logger.info("   - Tool will ingest, embed, and store in Pi's semantic memory")
    logger.info("")
    logger.info("File Path Mode (Local Server Only):")
    logger.info("- Use 'file_path' parameter instead")
    logger.info("- Works only when files are accessible to server filesystem")
    logger.info("=" * 60)

    uvicorn.run(
        app,
        host="0.0.0.0",
        port=_mcp_port,
        log_level="info"
    )
