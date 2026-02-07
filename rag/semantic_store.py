"""
Semantic Store - Enhanced vector store with metadata for semantic memory.

Design Principles (NON-NEGOTIABLE):
- Stores DOCUMENTS and CODE, not preferences or facts
- Embeddings are DERIVATIVE, not authoritative
- Vector DB scales independently from memory phases 1-3
- Supports citations and traceability
- Query-driven (no auto-retrieval)

Memory Type Separation:
- Symbolic Memory: Facts, preferences (authoritative)
- Episodic Memory: Agent lessons (advisory)
- Semantic Memory: Documents, code (non-authoritative)

Content Policy:
✅ ALLOWED:
• Documentation
• Code files
• READMEs
• Knowledge base articles
• Logs (summarized)
• External references

❌ FORBIDDEN:
• User preferences (→ Symbolic Memory)
• Decisions (→ Symbolic Memory)
• Constraints (→ Symbolic Memory)
• Agent lessons (→ Episodic Memory)
• Chat history
"""

import json
import os
import hashlib
import uuid
import logging
from typing import List, Dict, Any, Optional, Tuple, Set
from datetime import datetime, timezone
from pathlib import Path

import numpy as np

logger = logging.getLogger(__name__)

# Import embedding service at module level (no lazy import needed)
from .embedding import get_embedding_service


class DocumentChunk:
    """
    Represents a single chunk of a document in semantic memory.

    Attributes:
        chunk_id: Unique identifier for the chunk
        document_id: ID of the parent document
        content: The chunk content
        embedding: Vector embedding of the content
        metadata: Document metadata
        chunk_index: Position of this chunk in document
        created_at: Timestamp when chunk was created
    """

    VALID_TYPES = {"doc", "code", "note", "article", "reference"}

    def __init__(
        self,
        chunk_id: Optional[str] = None,
        document_id: str = "",
        content: str = "",
        embedding: Optional[List[float]] = None,
        metadata: Optional[Dict[str, Any]] = None,
        chunk_index: int = 0,
        created_at: Optional[str] = None
    ):
        self.chunk_id = chunk_id or str(uuid.uuid4())
        self.document_id = document_id
        self.content = content
        self.embedding = embedding or []
        self.metadata = metadata or {}
        self.chunk_index = chunk_index
        self.created_at = created_at or datetime.now(timezone.utc).isoformat()

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary representation."""
        return {
            "chunk_id": self.chunk_id,
            "document_id": self.document_id,
            "content": self.content,
            "embedding": self.embedding,
            "metadata": self.metadata,
            "chunk_index": self.chunk_index,
            "created_at": self.created_at
        }

    def validate_metadata(self) -> bool:
        """
        Validate metadata doesn't contain forbidden content.
        
        Forbidden:
        - User preferences (→ Symbolic Memory)
        - Decisions (→ Symbolic Memory)
        - Constraints (→ Symbolic Memory)
        - Agent lessons (→ Episodic Memory)
        - Chat history
        
        Note: "episode" and "episodic" are legitimate technical terms in this codebase
        and should be allowed in metadata and file content.
        
        Returns:
            True if valid, False if contains forbidden content
        """
        forbidden_keys = {
            "user_preference", "preference", "user_likes",
            "agent_decision", "decision", "system_decision",
            "agent_lesson",
            "chat_history", "conversation", "dialogue"
        }
        
        for key in forbidden_keys:
            if key in self.metadata:
                return False
        
        # Check if content looks like a preference/decision
        # Use phrase matching to avoid false positives on technical documentation
        content_lower = self.content.lower()
        
        # Check for user preferences
        user_pref_patterns = [
            "user prefers", "user likes", "user wants", "user preference",
            "the user prefers", "the user likes", "the user wants"
        ]
        for pattern in user_pref_patterns:
            if pattern in content_lower:
                return False
        
        # Check for system/agent decisions (only if about making decisions)
        decision_patterns = [
            "decision was made", "we decided to", "the system decided",
            "agent decided to", "system decided to"
        ]
        for pattern in decision_patterns:
            if pattern in content_lower:
                return False
        
        # Check for agent learning (avoid matching documentation terms)
        learning_patterns = [
            "agent learned that", "the agent learned that", "our agent learned",
            "lesson was that", "the lesson was that"
        ]
        for pattern in learning_patterns:
            if pattern in content_lower:
                return False
        
        return True
        
        return True


class SemanticStore:
    """
    Enhanced vector store for semantic memory with metadata.

    Features:
    - Document and code storage with embeddings
    - Metadata filtering and traceability
    - Chunk-level granularity with stable IDs
    - Citations support
    - Scales independently from memory phases 1-3

    Example:
        >>> store = SemanticStore("./data/semantic_index")
        >>> store.add_document("docs/api.md", content="# API Docs...", metadata={"type": "doc", "source": "docs/api.md"})
        >>> results = store.search("How does authentication work?", top_k=3)
    """

    def __init__(self, index_path: str = "./data/semantic_index"):
        """
        Initialize semantic store.

        Args:
            index_path: Path to store vector index and metadata
        """
        self.index_path = index_path

        # Core data structures
        self.chunks: List[DocumentChunk] = []
        self.document_ids: Set[str] = set()

        # Ensure index directory exists
        os.makedirs(index_path, exist_ok=True)
        os.makedirs(os.path.join(index_path, "metadata"), exist_ok=True)

        # Load existing index
        self.load()

    def add_document(
        self,
        content: str,
        metadata: Dict[str, Any],
        chunk_size: int = 500,
        chunk_overlap: int = 50
    ) -> List[str]:
        """
        Add a document to semantic store with automatic chunking.

        Args:
            content: Document content
            metadata: Document metadata (source, type, etc.)
            chunk_size: Target chunk size
            chunk_overlap: Overlap between chunks

        Returns:
            List of chunk_ids created

        Raises:
            ValueError: If metadata contains forbidden content
        """
        # Validate metadata doesn't contain forbidden content
        temp_chunk = DocumentChunk(document_id="temp", content=content[:100], metadata=metadata)
        if not temp_chunk.validate_metadata():
            forbidden_types = [
                "User preferences",
                "Decisions",
                "Constraints",
                "Agent lessons",
                "Chat history"
            ]
            raise ValueError(
                f"Forbidden content in metadata. Semantic memory can only store documents and code, not {', '.join(forbidden_types)}. "
                "Use Symbolic Memory for preferences/decisions and Episodic Memory for agent lessons."
            )

        # Generate document ID from source if provided
        source = metadata.get("source", "")
        document_id = self._generate_document_id(source) if source else str(uuid.uuid4())

        # Chunk the content
        chunks = self._chunk_content(content, chunk_size, chunk_overlap)

        # Create DocumentChunk objects with embeddings
        chunk_ids = []
        for i, chunk_text in enumerate(chunks):
            # Generate embedding for the chunk
            embedding = _generate_embedding(chunk_text)

            chunk = DocumentChunk(
                document_id=document_id,
                content=chunk_text,
                embedding=embedding,
                chunk_index=i,
                metadata={
                    **metadata,
                    "document_id": document_id,
                    "chunk_index": i,
                    "total_chunks": len(chunks)
                }
            )
            self.chunks.append(chunk)
            chunk_ids.append(chunk.chunk_id)

        self.document_ids.add(document_id)
        self.save()
        return chunk_ids

    def _generate_document_id(self, source: str) -> str:
        """
        Generate stable document ID from source path.

        Args:
            source: Source file path or URL

        Returns:
            Stable document ID
        """
        if not source:
            return str(uuid.uuid4())

        # Use hash of source for stable ID
        doc_hash = hashlib.md5(source.encode()).hexdigest()[:16]
        return f"doc_{doc_hash}"

    def _chunk_content(
        self,
        content: str,
        chunk_size: int = 500,
        chunk_overlap: int = 50
    ) -> List[str]:
        """
        Split content into semantically-meaningful chunks.

        Args:
            content: Content to split
            chunk_size: Target chunk size
            chunk_overlap: Overlap between chunks

        Returns:
            List of text chunks
        """
        if not content:
            return []

        chunks = []

        # Split by paragraphs first (semantic boundaries)
        paragraphs = content.split('\n\n')

        current_chunk = ""
        for para in paragraphs:
            para = para.strip()
            if not para:
                continue

            # If adding this paragraph exceeds chunk size
            if len(current_chunk) + len(para) + 2 > chunk_size:
                if current_chunk:
                    chunks.append(current_chunk.strip())

                # If paragraph itself is too long, split it
                if len(para) > chunk_size:
                    # Split by sentences
                    sentences = para.split('. ')
                    current = ""
                    for sent in sentences:
                        if len(current) + len(sent) + 1 > chunk_size:
                            if current:
                                chunks.append(current.strip() + ".")
                            current = sent
                        else:
                            current = f"{current} {sent}".strip() if current else sent
                    if current:
                        chunks.append(current.strip() + ".")
                else:
                    current_chunk = para
            else:
                current_chunk = f"{current_chunk}\n\n{para}".strip()

        # Don't forget last chunk
        if current_chunk:
            chunks.append(current_chunk.strip())

        # Apply overlap (preserve context between chunks)
        if chunk_overlap > 0 and len(chunks) > 1:
            overlapped = []
            for i, chunk in enumerate(chunks):
                if i > 0:
                    prev_chunk = chunks[i - 1]
                    # Get overlap from end of previous chunk
                    overlap_text = prev_chunk[-chunk_overlap:] if len(prev_chunk) > chunk_overlap else prev_chunk
                    chunk = f"...{overlap_text}...\n{chunk}"
                overlapped.append(chunk)
            chunks = overlapped

        return chunks

    def search(
        self,
        query_embedding: List[float],
        top_k: int = 3,
        metadata_filters: Optional[Dict[str, Any]] = None,
        min_score: float = 0.0
    ) -> List[Dict[str, Any]]:
        """
        Search for relevant chunks using cosine similarity.

        Args:
            query_embedding: Query vector embedding
            top_k: Number of results to return
            metadata_filters: Optional metadata filters
            min_score: Minimum similarity score

        Returns:
            List of dicts with chunk content, score, metadata, and citations
        """
        if not self.chunks:
            return []

        # Compute similarities for all chunks
        results = []
        for idx, chunk in enumerate(self.chunks):
            # Check metadata filters
            if metadata_filters and not self._matches_metadata(chunk.metadata, metadata_filters):
                continue

            # Check if chunk has embedding
            if not chunk.embedding:
                continue

            # Compute cosine similarity
            score = self._cosine_similarity(query_embedding, chunk.embedding)

            if score >= min_score:
                results.append({
                    "chunk_id": chunk.chunk_id,
                    "document_id": chunk.document_id,
                    "content": chunk.content,
                    "score": score,
                    "metadata": chunk.metadata,
                    "chunk_index": chunk.chunk_index,
                    "citation": f"{chunk.metadata.get('source', 'unknown')}:{chunk.chunk_index}"
                })

        # Sort by score (descending)
        results.sort(key=lambda x: x["score"], reverse=True)

        # Return top-k results
        return results[:top_k]

    def _cosine_similarity(self, a: List[float], b: List[float]) -> float:
        """
        Compute cosine similarity between two vectors.

        Args:
            a: First vector
            b: Second vector

        Returns:
            Cosine similarity score (0.0-1.0)
        """
        if not a or not b:
            return 0.0

        # Compute dot product
        dot = sum(x * y for x, y in zip(a, b))

        # Compute norms
        norm_a = sum(x * x for x in a) ** 0.5
        norm_b = sum(x * x for x in b) ** 0.5

        if norm_a == 0 or norm_b == 0:
            return 0.0

        return dot / (norm_a * norm_b)

    def _matches_metadata(self, item_metadata: Dict[str, Any], filters: Dict[str, Any]) -> bool:
        """
        Check if metadata matches all filter criteria.

        Args:
            item_metadata: Item's metadata
            filters: Filter criteria

        Returns:
            True if all filters match, False otherwise
        """
        for key, value in filters.items():
            if key not in item_metadata:
                return False

            if isinstance(value, (list, tuple)):
                # Check if item_metadata[key] is in value list
                if item_metadata[key] not in value:
                    return False
            elif item_metadata[key] != value:
                return False

        return True

    def get_chunk_by_id(self, chunk_id: str) -> Optional[DocumentChunk]:
        """
        Retrieve a chunk by its ID.

        Args:
            chunk_id: ID of the chunk

        Returns:
            DocumentChunk if found, None otherwise
        """
        for chunk in self.chunks:
            if chunk.chunk_id == chunk_id:
                return chunk
        return None

    def delete_document(self, document_id: str) -> int:
        """
        Delete all chunks for a document.

        Args:
            document_id: ID of the document

        Returns:
            Number of chunks deleted
        """
        before_count = len(self.chunks)
        self.chunks = [c for c in self.chunks if c.document_id != document_id]
        self.document_ids.discard(document_id)
        self.save()
        return before_count - len(self.chunks)

    def get_stats(self) -> Dict[str, Any]:
        """
        Get semantic store statistics.

        Returns:
            Dictionary with statistics
        """
        if not self.chunks:
            return {
                "total_chunks": 0,
                "total_documents": 0,
                "index_path": self.index_path
            }

        # Count by type
        type_counts = {}
        for chunk in self.chunks:
            doc_type = chunk.metadata.get("type", "unknown")
            type_counts[doc_type] = type_counts.get(doc_type, 0) + 1

        return {
            "total_chunks": len(self.chunks),
            "total_documents": len(self.document_ids),
            "by_type": type_counts,
            "index_path": self.index_path
        }

    def save(self) -> None:
        """
        Persist semantic store to disk.
        """
        # Save chunks with embeddings
        chunks_file = os.path.join(self.index_path, "chunks.json")
        with open(chunks_file, 'w') as f:
            chunks_data = [chunk.to_dict() for chunk in self.chunks]
            json.dump(chunks_data, f, indent=2)

        # Save metadata separately
        metadata_file = os.path.join(self.index_path, "metadata", "documents.json")
        documents_metadata = {}
        for chunk in self.chunks:
            doc_id = chunk.document_id
            if doc_id not in documents_metadata:
                documents_metadata[doc_id] = {
                    k: v for k, v in chunk.metadata.items()
                    if k not in ["document_id", "chunk_index", "total_chunks"]
                }

        with open(metadata_file, 'w') as f:
            json.dump(documents_metadata, f, indent=2)

    def load(self) -> None:
        """
        Load semantic store from disk.
        """
        chunks_file = os.path.join(self.index_path, "chunks.json")
        metadata_file = os.path.join(self.index_path, "metadata", "documents.json")

        # Load chunks
        if os.path.exists(chunks_file):
            try:
                with open(chunks_file, 'r') as f:
                    chunks_data = json.load(f)
                    self.chunks = [DocumentChunk(**data) for data in chunks_data]
            except Exception as e:
                logger.warning(f"Failed to load chunks: {e}")

        # Load document IDs
        if os.path.exists(metadata_file):
            try:
                with open(metadata_file, 'r') as f:
                    doc_metadata = json.load(f)
                    self.document_ids = set(doc_metadata.keys())
            except Exception as e:
                logger.warning(f"Failed to load metadata: {e}")


# Cache of semantic store instances keyed by index_path
# This allows multiple stores with different paths while maintaining efficiency
_semantic_store_cache: Dict[str, SemanticStore] = {}


def get_semantic_store(index_path: str = "./data/semantic_index") -> SemanticStore:
    """
    Get or create a semantic store instance for the given index path.

    This function maintains a cache of SemanticStore instances keyed by their
    index_path. This fixes BUG-INGEST-01 where different components using
    different paths would all get the same (wrong) instance.

    Args:
        index_path: Path to vector index (default: "./data/semantic_index")

    Returns:
        SemanticStore instance for the given path

    Example:
        >>> store1 = get_semantic_store("./data/store1")
        >>> store2 = get_semantic_store("./data/store2")
        >>> store1 is store2  # False - different paths get different instances
        False
        >>> store3 = get_semantic_store("./data/store1")
        >>> store1 is store3  # True - same path gets cached instance
        True
    """
    global _semantic_store_cache

    # Normalize the path to handle relative paths consistently
    normalized_path = os.path.abspath(os.path.expanduser(index_path))

    # Check if we already have an instance for this path
    if normalized_path not in _semantic_store_cache:
        logger.info(f"Creating new SemanticStore for path: {normalized_path}")
        _semantic_store_cache[normalized_path] = SemanticStore(normalized_path)
    else:
        logger.debug(f"Reusing cached SemanticStore for path: {normalized_path}")

    return _semantic_store_cache[normalized_path]


def _generate_embedding(content: str) -> List[float]:
    """
    Generate embedding for content.

    Args:
        content: Text to generate embedding for

    Returns:
        List of embedding values (empty list if service unavailable)
    """
    try:
        embedding_service = get_embedding_service()
        return embedding_service.embed_single(content)
    except Exception as e:
        logger.warning(f"Failed to generate embedding: {e}")
        return []
