"""
synapse - Local RAG system using llama-cpp-python

Components:
- ModelManager: Multi-model load/unload management
- EmbeddingService: Generate embeddings using GGUF models
- VectorStore: CPU-based vector storage with cosine similarity
- Retriever: Semantic document search
- RAGOrchestrator: Coordinate retrieval and LLM generation
- ingest_file/ingest_directory: Document ingestion tools
- SymbolicMemory: Deterministic, auditable memory subsystem (Phase 1)
- EpisodicMemory: Agent experience and lessons (Phase 3)
- SemanticMemory: Document and code retrieval (Phase 4)
"""

from .model_manager import ModelManager, ModelConfig, get_model_manager
from .vectorstore import VectorStore
from .embedding import EmbeddingService, get_embedding_service
from .retriever import Retriever, get_retriever
from .orchestrator import RAGOrchestrator, get_orchestrator
from .ingest import ingest_file, ingest_text, chunk_text
from .bulk_ingest import ingest_directory

# Symbolic Memory components (Phase 1)
from .memory_store import MemoryStore, MemoryFact, get_memory_store
from .memory_writer import MemoryWriter, extract_and_store
from .memory_reader import MemoryReader, get_memory_reader, inject_memory_context

# Episodic Memory components (Phase 3)
from .episodic_store import EpisodicStore, Episode, get_episodic_store
from .episode_extractor import EpisodeExtractor, create_simple_llm_func
from .episodic_reader import EpisodicReader, get_episodic_reader

# Semantic Memory components (Phase 4)
from .semantic_store import SemanticStore, DocumentChunk, get_semantic_store
from .semantic_ingest import SemanticIngestor, get_semantic_ingestor
from .semantic_retriever import SemanticRetriever, get_semantic_retriever
from .semantic_injector import SemanticInjector, get_semantic_injector

__all__ = [
    # Model Management
    'ModelManager',
    'ModelConfig',
    'get_model_manager',

    # Vector Store
    'VectorStore',

    # Embeddings
    'EmbeddingService',
    'get_embedding_service',

    # Retrieval
    'Retriever',
    'get_retriever',

    # Orchestration
    'RAGOrchestrator',
    'get_orchestrator',

    # Ingestion
    'ingest_file',
    'ingest_text',
    'ingest_directory',
    'chunk_text',

    # Symbolic Memory (Phase 1)
    'MemoryStore',
    'MemoryFact',
    'get_memory_store',
    'MemoryWriter',
    'extract_and_store',
    'MemoryReader',
    'get_memory_reader',
    'inject_memory_context',

    # Episodic Memory (Phase 3)
    'EpisodicStore',
    'Episode',
    'get_episodic_store',
    'EpisodeExtractor',
    'create_simple_llm_func',
    'EpisodicReader',
    'get_episodic_reader',

    # Semantic Memory (Phase 4)
    'SemanticStore',
    'DocumentChunk',
    'get_semantic_store',
    'SemanticIngestor',
    'get_semantic_ingestor',
    'SemanticRetriever',
    'get_semantic_retriever',
    'SemanticInjector',
    'get_semantic_injector',
]

__version__ = "1.3.0"
