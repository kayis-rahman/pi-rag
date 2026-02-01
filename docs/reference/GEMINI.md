# Synapse Project Context

## Project Overview

**Synapse** is a local-first Retrieval-Augmented Generation (RAG) system designed to act as an intelligent memory layer for AI agents. It uses a neurobiological metaphor to organize information into three distinct memory types:

1.  **Dendrites (Semantic Memory):** Vector-based document storage (ChromaDB) for grounded retrieval.
2.  **Synapses (Episodic Memory):** Experience-based learning and pattern recognition.
3.  **Cell Bodies (Symbolic Memory):** Authoritative facts and configuration.

The system exposes these capabilities via the **Model Context Protocol (MCP)**, allowing it to integrate seamlessly with MCP-compliant AI clients (like Claude Desktop or other agents).

## Architecture & Tech Stack

*   **Backend:** Python 3.8+
    *   **Framework:** FastAPI / Uvicorn (via `mcp-server`)
    *   **RAG Engine:** Llama.cpp (via `llama-cpp-python`), ChromaDB (Vector Store)
    *   **Protocol:** [Model Context Protocol (MCP)](https://modelcontextprotocol.io/)
*   **Documentation:** Next.js 15, Fumadocs UI, TailwindCSS, TypeScript.
*   **Infrastructure:** Docker Compose.
*   **Issue Tracking:** [GitHub Issues](https://github.com/kayis-rahman/synapse/issues) (Standard open-source workflow).

## Directory Structure

*   `mcp_server/`: Implementation of the MCP server and HTTP wrappers.
*   `rag/`: Core RAG logic, including memory stores, ingestion, and retrieval.
*   `configs/`: Configuration files for RAG parameters and models.
*   `docs/`: Documentation website source code (Next.js).
*   `scripts/`: Utility scripts for ingestion and status checks.

## Development Setup

### Prerequisites
*   Python 3.8+
*   Node.js 18+ (for documentation)
*   Docker & Docker Compose (optional, for containerized run)

### Installation (Local)

1.  **Install Python Dependencies:**
    ```bash
    pip install -e ".[dev,mcp]"
    ```
2.  **Environment Setup:**
    Create a `.env` file (reference `.env.example`):
    ```ini
    HOST=0.0.0.0
    PORT=8002
    PROJECT_ROOT=/path/to/data
    ```

### Running the System

*   **Start MCP Server:**
    ```bash
    synapse-mcp-server
    ```
*   **Check System Status:**
    ```bash
    synapse-system-status
    ```
*   **Bulk Ingestion:**
    ```bash
    synapse-bulk-ingest --dry-run
    ```

### Docker Usage

Run the MCP server using Docker Compose:

```bash
docker-compose -f docker-compose.mcp.yml up --build
```
*   **Port:** 8002 (HTTP MCP endpoint)
*   **Volumes:** Persists data to `rag-mcp-data` and models to `rag-mcp-models`.

### Documentation Development

To run the documentation site locally:

```bash
cd docs
npm install
npm run dev
```
Access at `http://localhost:3000`.

## Testing & Quality

*   **Python Testing:**
    ```bash
    pytest
    ```
*   **Linting/Formatting:**
    *   Python: `black`, `mypy` (implied by `dev` dependencies).
    *   TypeScript: `npm run lint` (in `docs/`).

## Key Conventions

*   **Memory Metaphor:** Code and documentation should strictly adhere to the neurobiological naming convention (Dendrites, Synapses, Cell Bodies).
*   **Local-First:** Design decisions should prioritize local execution and privacy (e.g., local embeddings, local vector store).
*   **MCP Standard:** All new tool capabilities must be exposed via the MCP server implementation.
