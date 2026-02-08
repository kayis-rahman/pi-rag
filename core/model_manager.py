"""
Multi-Model Manager - Load and unload GGUF models dynamically using llama-cpp-python.
Supports both local GGUF models and external API models.

This module provides efficient model management for:
- Chat/completion models (e.g., Qwen3-4B)
- Embedding models (e.g., nomic-embed-text)
- External API models (e.g., OpenAI, Llama.cpp server)

Features:
- Dynamic model loading/unloading to manage memory
- Model caching with LRU eviction
- Thread-safe operations
- Configurable GPU layers and context size
- Support for external APIs
"""

import json
import os
import threading
import time
import requests

from .logger import get_logger
logger = get_logger(__name__)

try:
    from llama_cpp import Llama
    LLAMA_CPP_AVAILABLE = True
except ImportError:
    LLAMA_CPP_AVAILABLE = False
    Llama = None


class ModelConfig:
    """Configuration for a single model."""
    def __init__(self, path, model_type, n_ctx=4096, n_gpu_layers=-1, n_batch=512, 
                 embedding=False, verbose=False, is_external=False, api_url="", 
                 api_key="", model_name=""):
        self.path = path
        self.model_type = model_type
        self.n_ctx = n_ctx
        self.n_gpu_layers = n_gpu_layers
        self.n_batch = n_batch
        self.embedding = embedding
        self.verbose = verbose
        # For external models
        self.is_external = is_external
        self.api_url = api_url
        self.api_key = api_key
        self.model_name = model_name


class LoadedModel:
    """Container for a loaded model with metadata."""
    def __init__(self, model, config, last_used=None, load_time=0.0):
        self.model = model  # Llama instance or None for external models
        self.config = config
        self.last_used = last_used if last_used is not None else time.time()
        self.load_time = load_time


class ModelManager:
    """
    Manages multiple GGUF models with dynamic loading/unloading.
    
    Usage:
        manager = ModelManager()
        manager.register_model("chat", ModelConfig(path="model.gguf", model_type="chat"))
        
        # Load and use model
        model = manager.get_model("chat")
        response = model.create_chat_completion(messages=[...])
        
        # Unload to free memory
        manager.unload_model("chat")
    """
    
    def __init__(self, config_path="./configs/models_config.json", max_loaded=2):
        """
        Initialize the model manager.
        
        Args:
            config_path: Path to models configuration JSON
            max_loaded: Maximum number of models to keep loaded (LRU eviction)
        """
        self.config_path = config_path
        self.max_loaded = max_loaded
        
        # Model registry and loaded models
        self._registry = {}
        self._loaded = {}
        self._lock = threading.RLock()
        
        # Load configuration if exists
        self._load_config()
    
    def _load_config(self):
        """Load model configurations from JSON file."""
        if not os.path.exists(self.config_path):
            return
            
        try:
            with open(self.config_path, 'r') as f:
                config = json.load(f)
            
            for name, model_config in config.get("models", {}).items():
                # Handle external models that don't have a path
                path = model_config.get("path", "")
                is_external = model_config.get("is_external", False)

                self._registry[name] = ModelConfig(
                    path=path,
                    model_type=model_config.get("type", "chat"),
                    n_ctx=model_config.get("n_ctx", 4096),
                    n_gpu_layers=model_config.get("n_gpu_layers", -1),
                    n_batch=model_config.get("n_batch", 512),
                    embedding=model_config.get("type") == "embedding",
                    verbose=model_config.get("verbose", False),
                    is_external=is_external,
                    api_url=model_config.get("api_url", ""),
                    api_key=model_config.get("api_key", ""),
                    model_name=model_config.get("model_name", "")
                )
        except Exception as e:
            logger.warning(f"Failed to load model config: {e}")
    
    def register_model(self, name, config):
        """
        Register a model configuration.
        
        Args:
            name: Unique identifier for the model
            config: Model configuration
        """
        with self._lock:
            self._registry[name] = config
    
    def _evict_lru(self):
        """Evict least recently used model if at capacity."""
        if len(self._loaded) < self.max_loaded:
            return
            
        # Find LRU model
        lru_name = min(self._loaded.keys(), key=lambda k: self._loaded[k].last_used)
        self.unload_model(lru_name)
    
    def load_model(self, name):
        """
        Load a model by name.
        
        Args:
            name: Model name (must be registered)
            
        Returns:
            Loaded Llama model instance or external API client
        """
        with self._lock:
            # Return if already loaded
            if name in self._loaded:
                self._loaded[name].last_used = time.time()
                return self._loaded[name].model
            
            config = self._registry[name]
            
            # Handle external models
            if config.is_external:
                logger.info(f"Using external model '{name}' at {config.api_url}")
                # For external models, we don't actually "load" anything but return a client
                # This is a placeholder - in practice you'd create an API client here
                return self._create_external_client(config)
            
            # Handle local GGUF models
            expanded_path = os.path.expanduser(config.path)
            if not os.path.exists(expanded_path):
                raise FileNotFoundError("Model file not found: " + config.path)
            
            # Evict LRU if needed
            self._evict_lru()

            # Load the model
            logger.info(f"Loading model '{name}' from {config.path}...")
            start_time = time.time()

            if LLAMA_CPP_AVAILABLE and Llama is not None:
                model = Llama(
                    model_path=expanded_path,
                    n_ctx=config.n_ctx,
                    n_gpu_layers=config.n_gpu_layers,
                    n_batch=config.n_batch,
                    embedding=config.embedding,
                    verbose=config.verbose
                )

                load_time = time.time() - start_time
                logger.info(f"Model '{name}' loaded in {load_time}s")

                # Store loaded model
                self._loaded[name] = LoadedModel(
                    model=model,
                    config=config,
                    last_used=time.time(),
                    load_time=load_time
                )

                return model
            else:
                raise ImportError("llama-cpp-python is required for local models. Install with: pip install llama-cpp-python")
    
    def _create_external_client(self, config):
        """Create an external API client."""
        
        class ExternalAPIClient:
            def __init__(self, api_url, api_key):
                self.api_url = api_url
                self.api_key = api_key
            
            def create_chat_completion(self, messages, **kwargs):
                """Make a chat completion request to external API."""
                headers = {
                    "Content-Type": "application/json"
                }
                if self.api_key:
                    headers["Authorization"] = "Bearer " + self.api_key
                
                payload = {
                    "messages": messages
                }
                # Update with additional kwargs
                for key, value in kwargs.items():
                    payload[key] = value
                
                try:
                    response = requests.post(
                        self.api_url,
                        json=payload,
                        headers=headers,
                        timeout=30
                    )
                    response.raise_for_status()
                    return response.json()
                except Exception as e:
                    raise Exception("External API error: " + str(e))
            
            def create_chat_completion_stream(self, messages, **kwargs):
                """Make a streaming chat completion request to external API."""
                headers = {
                    "Content-Type": "application/json"
                }
                if self.api_key:
                    headers["Authorization"] = "Bearer " + self.api_key
                
                payload = {
                    "messages": messages,
                    "stream": True
                }
                # Update with additional kwargs
                for key, value in kwargs.items():
                    payload[key] = value
                
                try:
                    response = requests.post(
                        self.api_url,
                        json=payload,
                        headers=headers,
                        timeout=30,
                        stream=True
                    )
                    response.raise_for_status()
                    
                    for line in response.iter_lines():
                        if line:
                            line = line.decode('utf-8').strip()
                            if line.startswith('data: '):
                                data = line[6:]  # Remove 'data: ' prefix
                                if data == '[DONE]':
                                    break
                                try:
                                    yield json.loads(data)
                                except json.JSONDecodeError:
                                    continue
                except Exception as e:
                    raise Exception("External API streaming error: " + str(e))

            def embed(self, text):
                """Generate embedding for text using external API."""
                # External APIs typically don't support embeddings in the same way
                # This is a placeholder that raises NotImplementedError
                raise NotImplementedError("External models do not support embedding generation")

        # Return an instance of the class, not the class itself
        return ExternalAPIClient(config.api_url, config.api_key)
    
    def get_model(self, name):
        """
        Get a model, loading it if necessary.
        
        Args:
            name: Model name
            
        Returns:
            Llama model instance or external API client
        """
        return self.load_model(name)
    
    def unload_model(self, name):
        """
        Unload a model to free memory.
        
        Args:
            name: Model name
            
        Returns:
            True if model was unloaded, False if not loaded
        """
        with self._lock:
            if name not in self._loaded:
                return False
            
            logger.info(f"Unloading model '{name}'...")
            
            # Delete model reference
            del self._loaded[name].model
            del self._loaded[name]
            
            # Force garbage collection
            import gc
            gc.collect()
            
            logger.info(f"Model '{name}' unloaded")
            return True
    
    def unload_all(self):
        """Unload all models."""
        with self._lock:
            names = list(self._loaded.keys())
            for name in names:
                self.unload_model(name)
    
    def is_loaded(self, name):
        """Check if a model is currently loaded."""
        return name in self._loaded
    
    def get_loaded_models(self):
        """Get list of currently loaded model names."""
        return list(self._loaded.keys())
    
    def get_model_info(self, name):
        """Get information about a model."""
        with self._lock:
            if name in self._loaded:
                loaded = self._loaded[name]
                return {
                    "name": name,
                    "loaded": True,
                    "path": loaded.config.path,
                    "type": loaded.config.model_type,
                    "n_ctx": loaded.config.n_ctx,
                    "load_time": loaded.load_time,
                    "last_used": loaded.last_used
                }
            elif name in self._registry:
                config = self._registry[name]
                return {
                    "name": name,
                    "loaded": False,
                    "path": config.path,
                    "type": config.model_type,
                    "n_ctx": config.n_ctx,
                    "is_external": config.is_external
                }
            return None
    
    def get_stats(self):
        """Get manager statistics."""
        return {
            "registered_models": list(self._registry.keys()),
            "loaded_models": list(self._loaded.keys()),
            "max_loaded": self.max_loaded
        }
    
    # Convenience methods for chat and embedding
    
    def chat_completion(
        self,
        model_name,
        messages,
        **kwargs
    ):
        """
        Generate a chat completion.

        Args:
            model_name: Name of chat model
            messages: List of message dicts with 'role' and 'content'
            **kwargs: Additional arguments for create_chat_completion

        Returns:
            Chat completion response
        """
        model = self.get_model(model_name)

        # Check if it's an external model
        if hasattr(model, 'create_chat_completion'):
            return model.create_chat_completion(messages=messages, **kwargs)
        else:
            # For local models
            return model.create_chat_completion(messages=messages, **kwargs)

    def generate_embeddings(
        self,
        model_name,
        texts
    ):
        """
        Generate embeddings for a list of texts.

        Args:
            model_name: Name of embedding model (must be registered)
            texts: List of strings to embed

        Returns:
            List of embedding vectors (each is a list of floats)
        """
        model = self.get_model(model_name)

        # For external models, embeddings are not supported yet
        config = self._registry.get(model_name)
        if config and config.is_external:
            raise NotImplementedError("External models do not support embedding generation yet")

        # For local GGUF models, use the embedding method
        if not LLAMA_CPP_AVAILABLE:
            raise ImportError("llama-cpp-python is required for embedding generation")

        embeddings = []
        # Use lock to protect thread-unsafe llama-cpp-python model
        try:
            with self._lock:
                for text in texts:
                    # Call the model's embed method (returns a list)
                    embedding = model.embed(text)
                    embeddings.append(embedding)
        except Exception as e:
            # Llama-cpp-python tokenizer may crash on certain inputs
            # Return empty embeddings on failure to prevent crashes
            import logging
            logger = logging.getLogger(__name__)
            logger.warning(f"Embedding generation failed for {len(texts)} texts: {e}")
            return [[] for _ in texts]

        return embeddings


# Singleton instance
_manager = None


def get_model_manager(config_path="./configs/models_config.json"):
    """Get or create the model manager singleton."""
    global _manager
    if _manager is None:
        _manager = ModelManager(config_path)
    return _manager