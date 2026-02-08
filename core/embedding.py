"""
Embedding Service - Uses llama-cpp-python for GGUF embedding models.

Supports:
- Local GGUF embedding models (e.g., nomic-embed-text, bge-small)
- Dynamic model loading via ModelManager
- Embedding caching for efficiency
- Thread-safe embedding generation
- Test mode with mock embeddings
"""

import json
import os
import threading
from typing import List, Dict, Any, Optional
from collections import OrderedDict

from .model_manager import get_model_manager, ModelConfig
from .logger import get_logger
logger = get_logger(__name__)


class EmbeddingService:
    """
    Embedding service using llama-cpp-python with GGUF models.
    
    Usage:
        service = EmbeddingService()
        embeddings = service.embed(["Hello world", "Another text"])
    """

    def __init__(self, config_path: str = "./configs/rag_config.json"):
        self.config_path = config_path
        self._load_config()

        # Cache for embeddings
        self._cache: OrderedDict[str, List[float]] = OrderedDict()

        # Model manager
        self._manager = get_model_manager()

        # Thread lock for safe concurrent access to embedding model
        self._lock = threading.Lock()

        # Test mode: use mock embeddings to avoid model loading issues
        import os
        self._test_mode = os.environ.get("SYNAPSE_TEST_MODE", "false").lower() == "true"
        if self._test_mode:
            logger.warning("SYNAPSE_TEST_MODE enabled: Using mock embeddings")

        # Register embedding model if path is set (not in test mode)
        if self.model_path and not self._test_mode:
            self._register_embedding_model()
        
    def _load_config(self) -> None:
        """Load configuration from JSON file."""
        self.model_path = ""
        self.model_name = "embedding"
        self.cache_enabled = True
        self.cache_size = 1000
        self.n_ctx = 2048
        self.n_gpu_layers = -1
        
        try:
            if os.path.exists(self.config_path):
                with open(self.config_path, 'r') as f:
                    config = json.load(f)
                self.model_path = config.get("embedding_model_path", "")
                self.model_name = config.get("embedding_model_name", "embedding")
                self.cache_enabled = config.get("embedding_cache_enabled", True)
                self.cache_size = config.get("embedding_cache_size", 1000)
                self.n_ctx = config.get("embedding_n_ctx", 2048)
                self.n_gpu_layers = config.get("embedding_n_gpu_layers", -1)
        except Exception as e:
            logger.warning(f"Failed to load config: {e}")
    
    def _register_embedding_model(self) -> None:
        """Register the embedding model with the model manager."""
        if not self.model_path or not os.path.exists(self.model_path):
            return
            
        config = ModelConfig(
            path=self.model_path,
            model_type="embedding",
            n_ctx=self.n_ctx,
            n_gpu_layers=self.n_gpu_layers,
            embedding=True,
            verbose=False
        )
        self._manager.register_model(self.model_name, config)
    
    def set_model(self, model_path: str, model_name: str = "embedding") -> None:
        """
        Set the embedding model to use.
        
        Args:
            model_path: Path to GGUF model file
            model_name: Name identifier for the model
        """
        self.model_path = model_path
        self.model_name = model_name

        logger.debug(f"Model path: {model_path}")
        if os.path.exists(model_path):
            self._register_embedding_model()
        else:
            raise FileNotFoundError(f"Model file not found: {model_path}")

    def _get_cache_key(self, text: str) -> str:
        """Generate cache key for text."""
        return text.lower().strip()[:500]  # Limit key length

    def _update_cache(self, texts: List[str], embeddings: List[List[float]]) -> None:
        """Update cache with new embeddings."""
        if not self.cache_enabled:
            return

        for text, emb in zip(texts, embeddings):
            key = self._get_cache_key(text)

            # Remove oldest if cache is full
            if len(self._cache) >= self.cache_size:
                self._cache.popitem(last=False)

            self._cache[key] = emb

    def embed(self, texts: List[str]) -> List[List[float]]:
        """
        Generate embeddings for a list of texts.
        
        Args:
            texts: List of strings to embed
            
        Returns:
            List of embedding vectors (each is a list of floats)
        """
        if not texts:
            return []
        
        if not self.model_path:
            raise ValueError(
                "Embedding model not configured. Set embedding_model_path in config "
                "or call set_model() with path to GGUF file."
            )
        
        # Check if model file exists before attempting to load
        expanded_path = os.path.expanduser(self.model_path)
        if not os.path.exists(expanded_path):
            raise FileNotFoundError(
                f"Embedding model file not found: {expanded_path}\n"
                f"Please ensure the model exists at the correct path.\n"
                f"Expected location: {expanded_path}\n"
                f"Model path from config: {self.model_path}"
            )
        
        # Check cache first
        results: List[Optional[List[float]]] = [None] * len(texts)
        uncached_texts: List[str] = []
        uncached_indices: List[int] = []


        if self.cache_enabled:
            for idx, text in enumerate(texts):
                key = self._get_cache_key(text)
                if key in self._cache:
                    results[idx] = self._cache[key]
                else:
                    uncached_texts.append(text)
                    uncached_indices.append(idx)
        else:
            uncached_texts = texts
            uncached_indices = list(range(len(texts)))


        # Generate embeddings for uncached texts (thread-safe)
        if uncached_texts:
            # In test mode, use mock embeddings to avoid model loading issues
            if self._test_mode:
                import hashlib
                import random
                # Use fixed seed for reproducibility
                random.seed(42)
                new_embeddings = []
                for _ in uncached_texts:
                    # Generate deterministic mock embedding (1024 dimensions)
                    # Using consistent seed ensures reproducibility
                    embedding = [random.random() for _ in range(1024)]
                    # Normalize embedding
                    norm = sum(x*x for x in embedding) ** 0.5
                    if norm > 0:
                        embedding = [x/norm for x in embedding]
                    new_embeddings.append(embedding)
            else:
                # Use lock to prevent concurrent model access
                try:
                    with self._lock:
                        new_embeddings = self._manager.generate_embeddings(
                            self.model_name,
                            uncached_texts
                        )
                except FileNotFoundError as e:
                    raise FileNotFoundError(
                        f"Embedding model not found during generation: {e}\n"
                        f"Please verify the model path in config and ensure the model file exists."
                    ) from e
                except Exception as e:
                    raise RuntimeError(
                        f"Embedding generation failed: {type(e).__name__}: {e}\n"
                        f"This may indicate a problem with the embedding model or its configuration."
                    ) from e

            # Fill in results and update cache
            for idx, emb in zip(uncached_indices, new_embeddings):
                results[idx] = emb

            self._update_cache(uncached_texts, new_embeddings)


        # Return results
        return [r for r in results if r is not None]

    def embed_single(self, text: str) -> List[float]:
        """
        Generate embedding for a single text.
        
        Args:
            text: String to embed
            
        Returns:
            Embedding vector as a list of floats
        """
        embeddings = self.embed([text])
        return embeddings[0] if embeddings else []

    def preload_model(self) -> None:
        """Preload the embedding model into memory."""
        if self.model_path:
            self._manager.load_model(self.model_name)
    
    def unload_model(self) -> None:
        """Unload the embedding model to free memory."""
        self._manager.unload_model(self.model_name)
    
    def is_model_loaded(self) -> bool:
        """Check if the embedding model is currently loaded."""
        return self._manager.is_loaded(self.model_name)
    
    def clear_cache(self) -> None:
        """Clear embedding cache."""
        self._cache.clear()
        
    def get_stats(self) -> Dict[str, Any]:
        """Get service statistics."""
        model_info = self._manager.get_model_info(self.model_name)
        return {
            "cache_size": len(self._cache),
            "cache_enabled": self.cache_enabled,
            "max_cache_size": self.cache_size,
            "model_path": self.model_path,
            "model_name": self.model_name,
            "model_loaded": self._manager.is_loaded(self.model_name),
            "model_info": model_info
        }
    
    def _generate_mock_embeddings(self, texts: List[str]) -> List[List[float]]:
        """Generate mock embeddings for fallback/testing.
        
        Creates deterministic mock embeddings based on text hash.
        Used when model loading fails or in test mode.
        
        Args:
            texts: List of strings to generate embeddings for
            
        Returns:
            List of embedding vectors (each is a list of 1024 floats)
        """
        import hashlib
        
        # Generate deterministic mock embeddings (1024 dimensions)
        embeddings = []
        
        for text in texts:
            # Use text hash as seed for consistency
            text_hash = hashlib.md5(text.encode('utf-8')).hexdigest()
            seed = int(text_hash[:8], 16)
            
            # Set seed for reproducibility
            import random
            random.seed(seed)
            
            # Generate 1024-dimensional embedding
            embedding = [random.random() for _ in range(1024)]
            
            # Normalize embedding to unit length
            norm = sum(x*x for x in embedding) ** 0.5
            if norm > 0:
                embedding = [x/norm for x in embedding]
            
            embeddings.append(embedding)
        
        return embeddings
 
 
# Singleton instance for easy access
_embedding_service: Optional[EmbeddingService] = None


def get_embedding_service(config_path: str = "./configs/rag_config.json") -> EmbeddingService:
    """Get or create the embedding service singleton."""
    global _embedding_service
    if _embedding_service is None:
        _embedding_service = EmbeddingService(config_path)
    return _embedding_service
