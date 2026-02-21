---
name: synapse-memory-management
description: Use when managing the three-tier memory architecture in SYNAPSE RAG system
---

# SYNAPSE Memory Management

## Overview
The SYNAPSE RAG system implements a three-tier memory architecture designed to mimic neural cognitive processes. This system provides AI agents with structured, reliable information management through semantic, episodic, and symbolic memory types.

## When to Use
- When implementing or working with cognitive memory systems for AI agents
- When managing persistent knowledge in AI applications
- When needing to distinguish between authoritative facts and advisory lessons
- When implementing memory management patterns in RAG systems

## Memory Architecture

### 1. Dendrites (Semantic Memory)
**Characteristics:**
- Vector-based document storage with BGE-M3 embeddings
- Grounded retrieval, zero hallucinations
- BGE-M3 embeddings, local model
- Project-based organization

**Authority Level:** 60% - Reference Suggestions
**Usage:** Store document embeddings and code chunks for semantic search

### 2. Synapses (Episodic Memory)
**Characteristics:**
- Lessons learned from experience and advisory intelligence
- Success/failure analysis
- Pattern recognition (85% confidence)
- Advisory intelligence for your system

**Authority Level:** 85% - High Priority Guidance
**Usage:** Store lessons learned, experiences, and best practices

### 3. Cell Bodies (Symbolic Memory)
**Characteristics:**
- Authoritative facts and system configuration
- Configuration, API endpoints, technical specifications
- System-wide settings
- Never questioned or overridden

**Authority Level:** 100% - Absolute Truth
**Usage:** Store critical facts, decisions, and constraints

## Memory Authority Hierarchy

### Symbolic Memory (100% - Absolute Truth)
- Authoritative facts explicitly stored
- Configuration, API endpoints, technical specs
- Never question or override
- Managed by `sy.mem.fact.add` tool

### Episodic Memory (85% - High Priority Guidance)
- Lessons learned from experience
- Best practices and advisory guidance
- Managed by `sy.mem.ep.add` tool

### Semantic Memory (60% - Reference Suggestions)
- Document embeddings, code chunks
- Suggestions that can be inaccurate
- Managed by `sy.mem.ingest` and `sy.mem.search` tools

## Memory Operations

### Adding Facts (Symbolic Memory)
```python
# Using sy.mem.fact.add tool
await backend.add_fact(
    project_id="myproject",
    fact_key="api_endpoint_v1",
    fact_value="https://api.example.com/v1",
    confidence=0.95,
    category="decision"
)
```

### Adding Episodes (Episodic Memory)
```python
# Using sy.mem.ep.add tool
await backend.add_episode(
    project_id="myproject",
    title="Authentication Failure Pattern",
    content="Situation: User authentication failed\nAction: Implemented rate limiting\nOutcome: Reduced brute force attacks\nLesson: Rate limiting improves security",
    lesson_type="pattern",
    quality=0.85
)
```

### Semantic Search
```python
# Using sy.mem.search tool
results = await backend.search(
    project_id="myproject",
    query="authentication patterns",
    memory_type="semantic",
    top_k=5
)
```

## Memory Management Best Practices

### 1. Authority Hierarchy Respect
Always respect the memory authority hierarchy:
- Symbolic memory (100%) - Critical facts
- Episodic memory (85%) - Lessons learned
- Semantic memory (60%) - Reference documents

### 2. Proper Fact Storage
When storing facts in symbolic memory:
- Use high confidence values (0.9+)
- Choose appropriate categories (preference, constraint, decision, fact)
- Ensure facts are authoritative and system-critical

### 3. Episode Quality Control
When storing episodes in episodic memory:
- Maintain quality scores (0.6+ for inclusion)
- Use descriptive lesson types
- Include clear situation-action-outcome-lesson structures

### 4. Semantic Ingestion
When ingesting documents into semantic memory:
- Use appropriate source types (file, code, web)
- Attach relevant metadata
- Ensure proper file path validation

## Common Mistakes
- Confusing memory types and their authority levels
- Using semantic memory as authoritative source
- Storing non-critical information in symbolic memory
- Not properly validating file paths during ingestion
- Ignoring the confidence thresholds for memory storage

## Real-World Impact
Proper memory management in SYNAPSE enables AI agents to:
- Maintain persistent knowledge across sessions
- Learn from experiences and store lessons
- Access structured information with high reliability
- Make decisions based on proper authority hierarchy
- Integrate with various MCP-compatible clients effectively
- Reduce cognitive load through organized knowledge management