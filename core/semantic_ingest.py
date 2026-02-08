"""
Semantic Ingest - Enhanced ingestion pipeline for semantic memory.

Design Principles (NON-NEGOTIABLE):
- Ingests DOCUMENTS and CODE, not preferences or facts
- Deterministic chunking with stable chunk IDs
- Query-driven (no auto-retrieval)
- Supports citations and traceability
- Scales independently from memory phases 1-3

Content Policy:
✅ ALLOWED:
• Documentation
• Code files
• READMEs
• Knowledge base articles
• Summarized logs
• External references

❌ FORBIDDEN:
• User preferences (→ Symbolic Memory)
• Decisions (→ Symbolic Memory)
• Constraints (→ Symbolic Memory)
• Agent lessons (→ Episodic Memory)
• Chat history
"""

import os
import json
from typing import List, Dict, Any, Optional, Tuple

from .logger import get_logger
logger = get_logger(__name__)
from pathlib import Path

from .semantic_store import DocumentChunk, SemanticStore, get_semantic_store
from .embedding import EmbeddingService, get_embedding_service


class SemanticIngestor:
    """
    Enhanced ingestion pipeline for semantic memory.

    Features:
    - Deterministic chunking with semantic boundaries
    - Stable chunk and document IDs
    - Embedding generation
    - Metadata validation
    - Batch ingestion support

    Example:
        >>> ingestor = SemanticIngestor()
        >>> chunk_ids = ingestor.ingest_file(
        ...     "docs/api.md",
        ...     metadata={"type": "doc", "source": "docs/api.md"}
        ... )
    """

    def __init__(
        self,
        semantic_store: Optional[SemanticStore] = None,
        embedding_service: Optional[EmbeddingService] = None
    ):
        """
        Initialize semantic ingestor.

        Args:
            semantic_store: Semantic store instance
            embedding_service: Embedding service instance
        """
        self.semantic_store = semantic_store or get_semantic_store()
        self.embedding_service = embedding_service or get_embedding_service()

    def ingest_file(
        self,
        file_path: str,
        metadata: Optional[Dict[str, Any]] = None,
        chunk_size: int = 500,
        chunk_overlap: int = 50
    ) -> List[str]:
        """
        Ingest a file into semantic memory.

        Args:
            file_path: Path to file to ingest
            metadata: Document metadata (type, source, etc.)
            chunk_size: Target chunk size
            chunk_overlap: Overlap between chunks

        Returns:
            List of chunk IDs created

        Raises:
            ValueError: If file doesn't exist or metadata is invalid
        """
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"File not found: {file_path}")

        # Read file content
        content = self._read_file(file_path)

        # Build metadata with source path
        file_metadata = metadata or {}
        file_metadata["source"] = file_path
        file_metadata["type"] = file_metadata.get("type", self._infer_type(file_path))
        file_metadata["filename"] = os.path.basename(file_path)
        file_metadata["size"] = os.path.getsize(file_path)

        # Add document to semantic store
        chunk_ids = self.semantic_store.add_document(
            content=content,
            metadata=file_metadata,
            chunk_size=chunk_size,
            chunk_overlap=chunk_overlap
        )

        logger.info(f"Ingested {file_path}: {len(chunk_ids)} chunks created")
        return chunk_ids

    def ingest_text(
        self,
        text: str,
        metadata: Dict[str, Any],
        chunk_size: int = 500,
        chunk_overlap: int = 50
    ) -> List[str]:
        """
        Ingest plain text into semantic memory.

        Args:
            text: Text content to ingest
            metadata: Document metadata (type, source, etc.)
            chunk_size: Target chunk size
            chunk_overlap: Overlap between chunks

        Returns:
            List of chunk IDs created

        Raises:
            ValueError: If metadata is invalid
        """
        # Build metadata if not provided
        text_metadata = metadata.copy()
        if "type" not in text_metadata:
            text_metadata["type"] = "doc"

        # Add document to semantic store
        chunk_ids = self.semantic_store.add_document(
            content=text,
            metadata=text_metadata,
            chunk_size=chunk_size,
            chunk_overlap=chunk_overlap
        )

        logger.info(f"Ingested text: {len(chunk_ids)} chunks created")
        return chunk_ids

    def ingest_directory(
        self,
        directory_path: str,
        metadata_filters: Optional[Dict[str, Any]] = None,
        file_pattern: str = "*",
        chunk_size: int = 500,
        chunk_overlap: int = 50
    ) -> Dict[str, List[str]]:
        """
        Ingest all files in a directory into semantic memory.

        Args:
            directory_path: Path to directory to ingest
            metadata_filters: Metadata filters (e.g., {"type": "code"})
            file_pattern: File pattern to match (e.g., "*.md", "*.py")
            chunk_size: Target chunk size
            chunk_overlap: Overlap between chunks

        Returns:
            Dict mapping file paths to chunk IDs
        """
        if not os.path.isdir(directory_path):
            raise ValueError(f"Directory not found: {directory_path}")

        results = {}

        # Find all matching files
        for root, dirs, files in os.walk(directory_path):
            # Skip hidden directories
            dirs[:] = [d for d in dirs if not d.startswith('.')]

            for filename in files:
                if not filename.endswith(file_pattern):
                    continue

                file_path = os.path.join(root, filename)

                # Build metadata
                file_metadata = metadata_filters or {}
                file_metadata["source"] = file_path
                file_metadata["type"] = file_metadata.get("type", self._infer_type(file_path))
                file_metadata["filename"] = filename

                # Ingest file
                try:
                    chunk_ids = self.ingest_file(
                        file_path=file_path,
                        metadata=file_metadata,
                        chunk_size=chunk_size,
                        chunk_overlap=chunk_overlap
                    )
                    results[file_path] = chunk_ids
                except Exception as e:
                    logger.warning(f"Failed to ingest {file_path}: {e}")

        total_chunks = sum(len(ids) for ids in results.values())
        logger.info(f"Directory ingestion complete: {len(results)} files, {total_chunks} chunks")

        return results

    def ingest_code(
        self,
        file_path: str,
        metadata: Optional[Dict[str, Any]] = None,
        chunk_size: int = 400,
        chunk_overlap: int = 50
    ) -> List[str]:
        """
        Ingest code file into semantic memory with code-aware chunking.

        Args:
            file_path: Path to code file
            metadata: Document metadata
            chunk_size: Target chunk size (smaller for code)
            chunk_overlap: Overlap between chunks

        Returns:
            List of chunk IDs created

        Raises:
            ValueError: If file doesn't exist or is not code
        """
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"Code file not found: {file_path}")

        # Read file content
        content = self._read_file(file_path)

        # Build metadata for code
        code_metadata = metadata or {}
        code_metadata["source"] = file_path
        code_metadata["type"] = "code"
        code_metadata["filename"] = os.path.basename(file_path)
        code_metadata["size"] = os.path.getsize(file_path)

        # Code-specific chunking (preserve function boundaries, etc.)
        # For now, use same chunking as documents
        # Could be enhanced with AST-based chunking for code

        # Add document to semantic store
        chunk_ids = self.semantic_store.add_document(
            content=content,
            metadata=code_metadata,
            chunk_size=chunk_size,
            chunk_overlap=chunk_overlap
        )

        logger.info(f"Ingested code file {file_path}: {len(chunk_ids)} chunks created")
        return chunk_ids

    def _read_file(self, file_path: str) -> str:
        """
        Read file content with encoding detection.

        Args:
            file_path: Path to file

        Returns:
            File content as string
        """
        encodings = ['utf-8', 'utf-8-sig', 'latin-1', 'cp1252']

        for encoding in encodings:
            try:
                with open(file_path, 'r', encoding=encoding) as f:
                    return f.read()
            except UnicodeDecodeError:
                continue

        # Fallback: read as binary and decode
        with open(file_path, 'rb') as f:
            content = f.read()
            return content.decode('utf-8', errors='replace')

    def _infer_type(self, file_path: str) -> str:
        """
        Infer document type from file extension.

        Args:
            file_path: Path to file

        Returns:
            Document type (doc, code, note, article, reference)
        """
        filename = os.path.basename(file_path).lower()

        # Code file extensions
        code_extensions = ['.py', '.js', '.ts', '.java', '.go', '.rs', '.c', '.cpp',
                         '.h', '.sh', '.rb', '.swift', '.kt', '.cs', '.php']

        for ext in code_extensions:
            if filename.endswith(ext):
                return 'code'

        # Document extensions
        doc_extensions = ['.md', '.rst', '.txt', '.pdf', '.doc', '.docx']

        for ext in doc_extensions:
            if filename.endswith(ext):
                return 'doc'

        # Default
        return 'doc'

    def get_stats(self) -> Dict[str, Any]:
        """
        Get ingestion statistics.

        Returns:
            Dictionary with statistics
        """
        store_stats = self.semantic_store.get_stats()

        return {
            "semantic_store": store_stats,
            "embedding_service": {
                "initialized": self.embedding_service is not None,
                "model_path": getattr(self.embedding_service, 'model_path', 'unknown') if self.embedding_service else None
            }
        }


# Singleton instance
_semantic_ingestor: Optional[SemanticIngestor] = None


def get_semantic_ingestor(
    semantic_store: Optional[SemanticStore] = None,
    embedding_service: Optional[EmbeddingService] = None
) -> SemanticIngestor:
    """
    Get or create the semantic ingestor singleton.

    Args:
        semantic_store: Semantic store instance
        embedding_service: Embedding service instance

    Returns:
        SemanticIngestor instance
    """
    global _semantic_ingestor
    if _semantic_ingestor is None:
        _semantic_ingestor = SemanticIngestor(semantic_store, embedding_service)
    return _semantic_ingestor
