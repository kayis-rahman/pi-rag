---
name: synapse-rag-system
description: Use when working with the SYNAPSE RAG system for AI agent knowledge management
---

# SYNAPSE RAG System

## Overview
The SYNAPSE RAG system is a local-first Retrieval-Augmented Generation system designed to provide intelligent knowledge retrieval for AI agents. It operates as a cognitive memory system with three-tier memory architecture that supports semantic, episodic, and symbolic memory types.

## When to Use
- When implementing AI agents that need persistent knowledge management
- When working with local-first RAG systems for agent cognition
- When managing knowledge bases with semantic, episodic, and symbolic memory layers
- When integrating with MCP (Model Context Protocol) clients like Claude Code or OpenCode

## Core Memory Architecture
The system implements a three-tier memory architecture with specific authority hierarchy:

1. **Dendrites (Semantic Memory)** - Vector-based document storage with BGE-M3 embeddings (60% confidence)
   - Grounded retrieval, zero hallucinations
   - BGE-M3 embeddings, local model
   - Project-based organization

2. **Synapses (Episodic Memory)** - Lessons learned from experience (85% confidence)
   - Success/failure analysis
   - Pattern recognition
   - Advisory intelligence for your system

3. **Cell Bodies (Symbolic Memory)** - Authoritative facts (100% accuracy)
   - Configuration settings
   - Technical specifications
   - System-wide settings
   - API endpoints, version numbers

## MCP Tools Reference
The system provides 7 MCP tools for memory operations:

### Tool 1: `sy.proj.list`
List all registered projects.

### Tool 2: `sy.src.list`
List all document sources in a project.

### Tool 3: `sy.ctx.get`
Get comprehensive context from all memory types (dendrites, synapses, cell bodies).

### Tool 4: `sy.mem.search`
Search dendrites (semantic memory) for relevant documents.

### Tool 5: `sy.mem.ingest`
Ingest a file into dendrites (semantic memory).

### Tool 6: `sy.mem.fact.add`
Add symbolic fact to cell bodies (100% accuracy).

### Tool 7: `sy.mem.ep.add`
Add episodic lesson to synapses (85% confidence).

## Quick Reference
| Tool | Memory Type | Purpose |
|------|-------------|---------|
| `sy.proj.list` | System | List projects |
| `sy.src.list` | Semantic | List document sources |
| `sy.ctx.get` | All | Get comprehensive context |
| `sy.mem.search` | Semantic | Semantic search |
| `sy.mem.ingest` | Semantic | Ingest documents |
| `sy.mem.fact.add` | Symbolic | Add authoritative facts |
| `sy.mem.ep.add` | Episodic | Add advisory lessons |

## Implementation
The system uses FastMCP with streamable HTTP transport for compatibility with Claude Code and OpenCode. It supports two ingestion modes:
1. HTTP Upload Flow - Recommended for remote access
2. Direct Ingestion - For local filesystem access

## Common Mistakes
- Confusing memory types and their authority levels
- Not respecting the authority hierarchy when retrieving information
- Attempting to use semantic memory as authoritative source
- Ignoring the distinction between symbolic (authoritative) and episodic (advisory) memory

## Real-World Impact
Agents using SYNAPSE can maintain persistent knowledge across sessions, learn from experiences, and access structured information with high reliability. The system supports multi-repo workspace management and provides a unified interface for knowledge management and retrieval.