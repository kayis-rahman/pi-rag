import json
import os
import numpy as np
from typing import List, Dict, Optional, Tuple, Any

from .logger import get_logger
logger = get_logger(__name__)


class VectorStore:
    """
    CPU-based vector store with cosine similarity search.
    Persists to disk in data/rag_index/ directory.
    """

    def __init__(self, index_path: str = "./data/rag_index"):
        self.index_path = index_path
        self.docs: List[str] = []
        self.vectors: List[List[float]] = []
        self.metadata: List[Dict[str, Any]] = []

        # Ensure index directory exists
        os.makedirs(index_path, exist_ok=True)

        # Try to load existing index
        self.load(index_path)

    def add(self, docs: List[str], vectors: List[List[float]], metadata: Optional[List[Dict[str, Any]]] = None) -> None:
        """
        Add documents with their embeddings and metadata to the store.
        """
        if len(docs) != len(vectors):
            raise ValueError(f"docs and vectors length mismatch: {len(docs)} vs {len(vectors)}")

        self.docs.extend(docs)
        self.vectors.extend(vectors)

        if metadata is not None:
            if len(metadata) != len(docs):
                raise ValueError(f"metadata and docs length mismatch: {len(metadata)} vs {len(docs)}")
            self.metadata.extend(metadata)
        else:
            self.metadata.extend([{} for _ in docs])

    def _cosine(self, a: List[float], b: List[float]) -> float:
        """
        Compute cosine similarity between two vectors.
        """
        if not a or not b:
            return 0.0

        dot = sum(x * y for x, y in zip(a, b))
        norm_a = sum(x * x for x in a) ** 0.5
        norm_b = sum(x * x for x in b) ** 0.5

        if norm_a == 0 or norm_b == 0:
            return 0.0

        return dot / (norm_a * norm_b)

    def _matches_filters(self, item_metadata: Dict[str, Any], filters: Dict[str, Any]) -> bool:
        """
        Check if metadata matches all filter criteria.
        All filters must match (AND logic).
        """
        for key, value in filters.items():
            if key not in item_metadata or item_metadata[key] != value:
                return False
        return True

    def search(self, query_vector: List[float], top_k: int = 3, metadata_filters: Optional[Dict[str, Any]] = None) -> List[Tuple[str, float, Dict[str, Any]]]:
        """
        Search for top-k most similar documents using cosine similarity.
        Returns: List of (document, score, metadata) tuples
        """
        if not self.vectors:
            return []

        # Compute similarities for all vectors
        scores = []
        for idx, vec in enumerate(self.vectors):
            if metadata_filters and not self._matches_filters(self.metadata[idx], metadata_filters):
                continue
            score = self._cosine(query_vector, vec)
            scores.append((idx, score))

        # Sort by score (descending)
        scores.sort(key=lambda x: x[1], reverse=True)

        # Return top-k results
        results = []
        for idx, score in scores[:top_k]:
            results.append((self.docs[idx], score, self.metadata[idx]))

        return results

    def save(self, path: Optional[str] = None) -> None:
        """
        Persist vector store to disk.
        """
        target = path or self.index_path
        os.makedirs(target, exist_ok=True)

        # Save vectors as numpy array
        np.save(os.path.join(target, 'vectors.npy'), np.array(self.vectors, dtype=np.float32))

        # Save documents as JSON
        with open(os.path.join(target, 'docs.json'), 'w', encoding='utf-8') as f:
            json.dump(self.docs, f, ensure_ascii=False)

        # Save metadata as JSON
        with open(os.path.join(target, 'meta.json'), 'w', encoding='utf-8') as f:
            json.dump(self.metadata, f, ensure_ascii=False)

    def load(self, path: Optional[str] = None) -> None:
        """
        Load vector store from disk.
        """
        target = path or self.index_path
        if not os.path.exists(target):
            # Directory doesn't exist, initialize empty
            return

        vectors_file = os.path.join(target, 'vectors.npy')
        docs_file = os.path.join(target, 'docs.json')
        meta_file = os.path.join(target, 'meta.json')

        # Check if all files exist
        if not all(os.path.exists(f) for f in [vectors_file, docs_file, meta_file]):
            # Incomplete index, initialize empty
            return

        # Load vectors
        try:
            vectors = np.load(vectors_file)
            self.vectors = vectors.tolist()
        except Exception as e:
            logger.warning(f"Failed to load vectors: {e}")
            self.vectors = []

        # Load documents
        try:
            with open(docs_file, 'r', encoding='utf-8') as f:
                self.docs = json.load(f)
        except Exception as e:
            logger.warning(f"Failed to load docs: {e}")
            self.docs = []

        # Load metadata
        try:
            with open(meta_file, 'r', encoding='utf-8') as f:
                self.metadata = json.load(f)
        except Exception as e:
            logger.warning(f"Failed to load metadata: {e}")
            self.metadata = []

        # Validate lengths
        min_len = min(len(self.docs), len(self.vectors), len(self.metadata))
        self.docs = self.docs[:min_len]
        self.vectors = self.vectors[:min_len]
        self.metadata = self.metadata[:min_len]

    def clear(self) -> None:
        """
        Clear all data from vector store.
        """
        self.docs = []
        self.vectors = []
        self.metadata = []

    def get_stats(self) -> Dict[str, int]:
        """
        Get statistics about the vector store.
        """
        return {
            "total_docs": len(self.docs),
            "total_vectors": len(self.vectors),
            "vector_dimension": len(self.vectors[0]) if self.vectors else 0
        }
