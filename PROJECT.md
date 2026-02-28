# Project: Synapse - Memory-Agentic Development System

## Project Overview
This project is a Java-based memory-agentic development system that integrates with external LLM services. The system is designed to work across distributed hardware setups with memory management and agent orchestration capabilities.

## Current State Analysis
The repository appears to be in the middle of a significant refactoring/migration process, with many files deleted and modified. Based on the documentation in CLAUDE.md, this system includes:
- Java-based memory-agentic system with gRPC communication
- Episodic, semantic, and knowledge graph memory layers
- Agent orchestration components
- Workflow management
- External API integration with vLLM Python service and TEI for embeddings
- CLI interface for system management, data ingestion, and querying

## Objectives
1. Establish a robust foundation for a memory-agentic system
2. Implement proper project structure and development workflow
3. Define clear requirements and specifications
4. Create comprehensive documentation and roadmap
5. Set up proper development environments and CI/CD

## Target Platform
- Java-based applications
- Integration with external LLM services via HTTP
- Support for distributed hardware setups (M1, Pi5, GTX 5090)

## Technology Stack
- Java Spring Boot for backend services
- gRPC for inter-component communication
- Redis-like storage for episodic memory
- Qdrant for semantic memory
- Kuzu for knowledge graph storage
- vLLM Python service for LLM inference
- TEI for embedding generation
- Docker containers for deployment
- Kubernetes for orchestration (planned)

## Key Features
- Multi-layer memory system (episodic, semantic, knowledge graph)
- Agent orchestration components
- Workflow management for continuity
- External API integration with LLM services
- CLI interface for system management
- Comprehensive testing strategy