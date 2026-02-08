"""
RAG Orchestrator - Coordinates retrieval and LLM generation using llama-cpp-python.

Features:
- Automatic context injection from retrieved documents
- Support for disabling RAG via system message keyword
- Multi-model support (separate embedding and chat models)
- Streaming and non-streaming responses
- Symbolic memory integration (deterministic, auditable)
"""

import json
import os
from typing import List, Dict, Any, Optional, Generator

from .logger import get_logger
logger = get_logger(__name__)

class RAGOrchestrator:
    """
    Orchestrates RAG pipeline: retrieval + LLM generation.
    
    Usage:
        orchestrator = RAGOrchestrator(config_path="./configs/rag_config.json")
        response = orchestrator.chat(
            messages=[{"role": "user", "content": "How does auth work?"}]
        )
    """
    
    def __init__(self, config_path: str = "./configs/rag_config.json"):
        self.config_path = config_path
        self._load_config()
        # Initialize components
        from .model_manager import get_model_manager, ModelConfig
        from .retriever import get_retriever
        from .memory_reader import get_memory_reader

        try:
            self._manager = get_model_manager()
            self._retriever = get_retriever(config_path)
            self._memory_reader = get_memory_reader(self.memory_db_path)

            # Register chat model if configured and it's a local model
            if self.chat_model_path and self.chat_model_name in self._manager._registry:
                config = self._manager._registry[self.chat_model_name]
                if not config.is_external:
                    self._register_chat_model()

        except Exception as e:
            logger.warning(f"Failed to initialize orchestrator dependencies: {e}")
    
    def _load_config(self) -> None:
        """Load configuration."""
        # Defaults
        self.rag_enabled = True
        self.top_k = 3
        self.disable_keyword = "disable-rag"
        self.chat_model_path = ""
        self.chat_model_name = "chat"
        self.n_ctx = 32768
        self.n_gpu_layers = -1
        self.temperature = 0.7
        self.max_tokens = 2048
        self.memory_enabled = True
        self.memory_db_path = "./data/memory.db"
        self.memory_scope = "session"
        self.memory_min_confidence = 0.7
        self.memory_max_facts = 10
        self.file_path_mode_enabled = False
        self.context_injection_enabled = False

        try:
            if os.path.exists(self.config_path):
                with open(self.config_path, 'r') as f:
                    config = json.load(f)

                self.rag_enabled = config.get("rag_enabled", True)
                self.top_k = config.get("top_k", 3)
                self.disable_keyword = config.get("rag_disable_keyword", "disable-rag")
                self.chat_model_path = config.get("chat_model_path", "")
                self.chat_model_name = config.get("chat_model_name", "chat")
                self.n_ctx = config.get("chat_n_ctx", 32768)
                self.n_gpu_layers = config.get("chat_n_gpu_layers", -1)
                self.temperature = config.get("temperature", 0.7)
                self.max_tokens = config.get("max_tokens", 2048)

                # Memory configuration
                self.memory_enabled = config.get("memory_enabled", True)
                self.memory_db_path = config.get("memory_db_path", "./data/memory.db")
                self.memory_scope = config.get("memory_scope", "session")
                self.memory_min_confidence = config.get("memory_min_confidence", 0.7)
                self.memory_max_facts = config.get("memory_max_facts", 10)

                # Feature toggle configuration
                self.file_path_mode_enabled = config.get("file_path_mode_enabled", True)
                self.context_injection_enabled = config.get("context_injection_enabled", True)
        except Exception as e:
            logger.warning(f"Failed to load orchestrator config: {e}")
    
    def _register_chat_model(self) -> None:
        """Register chat model with model manager."""
        if not self.chat_model_path or not os.path.exists(self.chat_model_path):
            return
            
        from .model_manager import ModelConfig

        config = ModelConfig(
            path=self.chat_model_path,
            model_type="chat",
            n_ctx=self.n_ctx,
            n_gpu_layers=self.n_gpu_layers,
            embedding=False,
            verbose=False
        )
        self._manager.register_model(self.chat_model_name, config)
    
    def set_chat_model(self, model_path: str, model_name: str = "chat") -> None:
        """
        Set the chat model to use.
        
        Args:
            model_path: Path to GGUF model file
            model_name: Name identifier for the model
        """
        self.chat_model_path = model_path
        self.chat_model_name = model_name
        
        if os.path.exists(model_path):
            self._register_chat_model()
        else:
            raise FileNotFoundError(f"Model file not found: {model_path}")
    
    def _should_use_rag(self, messages: List[Dict[str, str]]) -> bool:
        """Check if RAG should be used based on messages."""
        if not self.rag_enabled:
            return False
        
        # Check system message for disable keyword
        for msg in messages:
            if msg.get("role") == "system":
                content = msg.get("content", "").lower()
                if self.disable_keyword.lower() in content:
                    return False
        
        return True
    
    def _extract_query(self, messages: List[Dict[str, str]]) -> str:
        """Extract the query from messages (last user message)."""
        for msg in reversed(messages):
            if msg.get("role") == "user":
                return msg.get("content", "")
        return ""
    
    def _inject_context(
        self,
        messages: List[Dict[str, Any]],
        context: str,
        memory_context: str = ""
    ) -> List[Dict[str, Any]]:
        """Inject retrieved context and memory into messages."""
        # Check if context injection is disabled in config
        if not self.context_injection_enabled:
            return messages

        if not context and not memory_context:
            return messages

        if not context and not memory_context:
            return messages

        # Create augmented messages
        augmented = []

        # Add or augment system message with contexts
        has_system = any(m.get("role") == "system" for m in messages)

        # Build combined context
        context_parts = []
        if memory_context:
            context_parts.append(memory_context)
        if context:
            context_parts.append(f"Relevant Context:\n{context}")

        combined_context = "\n\n---\n".join(context_parts)

        if has_system:
            for msg in messages:
                if msg.get("role") == "system":
                    augmented.append({
                        "role": "system",
                        "content": f"{msg['content']}\n\n---\n{combined_context}"
                    })
                else:
                    augmented.append(msg)
        else:
            # Add new system message with context
            augmented.append({
                "role": "system",
                "content": f"Use the following information to help answer questions:\n\n{combined_context}"
            })
            augmented.extend(messages)

        return augmented

    def _get_memory_context(self, messages: List[Dict[str, str]]) -> str:
        """Get memory context for the current interaction."""
        if not self.memory_enabled or not hasattr(self, '_memory_reader'):
            return ""

        try:
            # Build memory context
            memory_context = self._memory_reader.build_memory_context(
                scopes=[self.memory_scope],
                min_confidence=self.memory_min_confidence,
                max_facts=self.memory_max_facts
            )
            return memory_context
        except Exception as e:
            logger.warning(f"Failed to get memory context: {e}")
            return ""

    def chat(
        self,
        messages: List[Dict[str, str]],
        model_name: Optional[str] = None,
        temperature: Optional[float] = None,
        max_tokens: Optional[int] = None,
        use_rag: Optional[bool] = None,
        metadata_filters: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Generate a chat response with optional RAG and memory augmentation.

        Args:
            messages: List of message dicts with 'role' and 'content'
            temperature: Sampling temperature
            max_tokens: Maximum tokens to generate
            use_rag: Override RAG usage (None = auto-detect)
            metadata_filters: Filters for document retrieval

        Returns:
            Response dict with 'content', 'rag_context', 'sources', 'memory_used'
        """
        # Use specified model or default
        model_to_use = model_name or self.chat_model_name

        # Determine if RAG should be used
        should_rag = use_rag if use_rag is not None else self._should_use_rag(messages)

        # Get memory context
        memory_context = self._get_memory_context(messages)

        # Retrieve context if RAG is enabled
        context = ""
        sources = []

        if should_rag:
            query = self._extract_query(messages)
            if query:
                context, sources = self._retriever.search_with_context(
                    query,
                    top_k=self.top_k,
                    metadata_filters=metadata_filters
                )

        # Inject context and memory into messages
        augmented_messages = self._inject_context(messages, context, memory_context) if (context or memory_context) else messages

        # Generate response
        temp = temperature if temperature is not None else self.temperature
        tokens = max_tokens if max_tokens is not None else self.max_tokens

        try:
            # Get model info to check if it's external
            model_info = self._manager.get_model_info(model_to_use)

            if model_info and model_info.get("is_external", False):
                # For external models, don't pass local model parameters
                response = self._manager.chat_completion(
                    model_to_use,
                    augmented_messages
                )
            else:
                # For local models, pass all parameters
                response = self._manager.chat_completion(
                    model_to_use,
                    augmented_messages,
                    temperature=temp,
                    max_tokens=tokens
                )

            # Extract content from response
            content = ""
            if response and isinstance(response, dict):
                choices = response.get("choices", [])
                if choices:
                    choice = choices[0]
                    if "message" in choice:
                        content = choice["message"].get("content", "")
                    elif "text" in choice:
                        content = choice["text"]

            return {
                "content": content,
                "rag_used": should_rag and bool(context),
                "rag_context": context,
                "sources": sources,
                "memory_used": bool(memory_context),
                "memory_context": memory_context,
                "model": model_to_use,
                "raw_response": response
            }
        except Exception as e:
            logger.error(f"Error generating response: {e}")
            return {
                "content": f"Error: {str(e)}",
                "rag_used": False,
                "rag_context": "",
                "sources": [],
                "memory_used": False,
                "memory_context": "",
                "model": model_to_use,
                "raw_response": None
            }

    def chat_stream(
        self,
        messages: List[Dict[str, str]],
        model_name: Optional[str] = None,
        temperature: Optional[float] = None,
        max_tokens: Optional[int] = None,
        use_rag: Optional[bool] = None,
        metadata_filters: Optional[Dict[str, Any]] = None
    ) -> Generator[str, None, None]:
        """
        Generate a streaming chat response.
        
        Yields:
            Content tokens as they are generated
        """
        if not self.chat_model_path:
            raise ValueError("Chat model not configured.")
        
        # Use specified model or default
        model_to_use = model_name or self.chat_model_name

        # Check if the model is registered
        if model_to_use not in self._manager._registry:
            raise ValueError(f"Model '{model_to_use}' not registered.")

        # Determine if RAG should be used
        should_rag = use_rag if use_rag is not None else self._should_use_rag(messages)

        # Retrieve context if RAG is enabled
        context = ""

        if should_rag:
            query = self._extract_query(messages)
            if query:
                context, _ = self._retriever.search_with_context(
                    query,
                    top_k=self.top_k,
                    metadata_filters=metadata_filters
                )

        # Inject context into messages
        augmented_messages = self._inject_context(messages, context) if context else messages

        # Get model and stream
        try:
            model = self._manager.get_model(model_to_use)
            model_info = self._manager.get_model_info(model_to_use)
            
            temp = temperature if temperature is not None else self.temperature
            tokens = max_tokens if max_tokens is not None else self.max_tokens
            
             # For now, treat all models the same way for streaming
            for chunk in model.create_chat_completion(
                messages=augmented_messages,  # type: ignore[arg-type]
                temperature=temp,
                max_tokens=tokens,
                stream=True
            ):
                # Access streaming response chunks
                choices = chunk.get("choices", [])  # type: ignore[assignment]
                if choices and len(choices) > 0:
                    choice = choices[0]
                    delta = choice.get("delta", {})  # type: ignore[attr-defined]
                    content = delta.get("content", "")  # type: ignore[attr-defined]
                    if content:
                        yield content
                        
        except Exception as e:
            logger.error(f"Stream error: {e}")

    def preload_models(self) -> None:
        """Preload both chat and embedding models."""
        if self.chat_model_path:
            self._manager.load_model(self.chat_model_name)
        # For now we don't have access to the retriever's embedded service directly

    def unload_models(self) -> None:
        """Unload all models to free memory."""
        self._manager.unload_all()

    def get_stats(self) -> Dict[str, Any]:
        """Get orchestrator statistics."""
        stats = {
            "rag_enabled": self.rag_enabled,
            "chat_model": self.chat_model_name,
            "model_manager": str(type(self._manager))
        }

        # Add memory stats if enabled
        if self.memory_enabled and hasattr(self, '_memory_reader'):
            try:
                memory_stats = self._memory_reader.get_summary()
                stats["memory"] = {
                    "enabled": True,
                    "db_path": self.memory_db_path,
                    "scope": self.memory_scope
                }
                stats["memory"].update(memory_stats)
            except Exception as e:
                logger.warning(f"Failed to get memory stats: {e}")
                stats["memory"] = {"enabled": True, "error": str(e)}
        else:
            stats["memory"] = {"enabled": False}

        return stats

# Singleton instance
_orchestrator: Optional[RAGOrchestrator] = None


def get_orchestrator(config_path: str = "./configs/rag_config.json") -> RAGOrchestrator:
    """Get or create the orchestrator singleton."""
    global _orchestrator
    if _orchestrator is None:
        _orchestrator = RAGOrchestrator(config_path)
    return _orchestrator
