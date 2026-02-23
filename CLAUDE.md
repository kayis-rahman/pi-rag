# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is the SYNAPSE repository, a local-first RAG (Retrieval-Augmented Generation) system that connects your knowledge to AI using a three-tier memory system (symbolic, episodic, semantic) and MCP (Model Context Protocol) integration.

## Architecture & Structure

The codebase is organized around:
- Core RAG functionality with three memory layers (symbolic, episodic, semantic)
- MCP protocol server implementation
- HTTP API layer for remote access
- CLI tools for command-line interaction
- Documentation system built with VitePress

Key components:
- `core/` - Core RAG system and memory management
- `mcp_server/` - MCP server implementation
- `scripts/` - Utility scripts and setup
- `docs/` - Documentation system (VitePress-based)
- `tests/` - Test suite

## Development Setup

### Initial Setup
```bash
# Install in development mode
pip install -e ".[dev]"

# Install pre-commit hooks
pip install pre-commit
pre-commit install
```

### Running Tests
```bash
# Run all tests
pytest

# Run specific test file
pytest tests/test_memory.py

# Run with coverage
pytest --cov=rag tests/

# Run a single test
pytest tests/test_memory.py::test_specific_function -v
```

### Code Quality
```bash
# Format code
black core/ mcp_server/ scripts/

# Type check
mypy core/
```

## Common Development Tasks

### Running the MCP Server
```bash
# Start the MCP server
synapse-mcp-server

# Start with custom port
synapse-mcp-server --port 8080
```

### Ingesting Documents
```bash
# Ingest a file
synapse ingest file.txt

# Ingest with custom chunk size
synapse ingest file.txt --chunk-size 1000
```

### Querying Knowledge Base
```bash
# Query the knowledge base
synapse query "How does system work?"

# Query with specific format
synapse query "API configuration" -f json
```

## Documentation System

The documentation is built with VitePress and located in `docs/app/`. It's organized by:
- Getting Started
- Architecture
- Usage
- API Reference
- Development

To build documentation:
```bash
cd docs/app
npm run docs:build
```

## Testing Strategy

Tests are organized in the `tests/` directory and cover:
- Core memory operations
- MCP protocol functionality
- CLI command behavior
- API endpoints
- Edge cases and error handling

## Key Technologies

- Python 3.8+
- llama-cpp-python for LLM inference
- BGE-M3 for local embeddings
- JSON-based semantic storage
- SQLite for symbolic and episodic memory
- MCP (Model Context Protocol) for AI integration
- VitePress for documentation

## Branch Workflow

Follows GitFlow-style workflow:
- `develop` - Integration branch
- `feature/*` - Feature development
- `bug/*` - Bug fixes
- `hotfix/*` - Critical production fixes

## Important Directories

- `core/` - Core RAG system implementation
- `mcp_server/` - MCP server and protocol handlers
- `scripts/` - Setup and utility scripts
- `tests/` - Test suite
- `docs/app/` - Documentation source
- `synapse/` - Package root containing main modules

## Release Process

Releases are managed through standard Python packaging with:
- Version bumping in setup.py/pyproject.toml
- CHANGELOG updates
- Git tagging
- PyPI publishing