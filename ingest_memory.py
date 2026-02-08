#!/usr/bin/env python3
"""
Comprehensive Semantic Memory Ingestion Script

This script ingests key documentation and code files into semantic memory
to populate the RAG system with comprehensive knowledge about the synapse project.

Usage:
    python3 ingest_memory.py
"""

import sys
import os
import json
import sqlite3
from pathlib import Path
from datetime import datetime, timezone

# Add project root to path
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root))

from rag.ingest import chunk_text
from rag.vectorstore import VectorStore
from rag.semantic_store import SemanticStore

def get_data_dir():
    """Get the data directory path."""
    return "/opt/synapse/data"

def get_config():
    """Load RAG configuration."""
    config_path = project_root / "configs" / "rag_config.json"
    if config_path.exists():
        with open(config_path, 'r') as f:
            return json.load(f)
    return {}

def ingest_file_to_semantic_store(file_path: str, source_type: str = "code"):
    """
    Ingest a single file into semantic memory.
    
    Args:
        file_path: Path to the file
        source_type: Type of source (code, doc, etc.)
    
    Returns:
        Number of chunks created
    """
    config = get_config()
    chunk_size = config.get('chunk_size', 500)
    chunk_overlap = config.get('chunk_overlap', 50)
    
    if not os.path.exists(file_path):
        print(f"  ❌ File not found: {file_path}")
        return 0
    
    try:
        # Read file content
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Get file metadata
        file_path_obj = Path(file_path)
        metadata = {
            "source_type": source_type,
            "file_name": file_path_obj.name,
            "file_path": str(file_path_obj.absolute()),
            "file_size": len(content),
            "ingested_at": datetime.now(timezone.utc).isoformat()
        }
        
        # Chunk the content
        chunks = chunk_text(content, chunk_size=chunk_size, chunk_overlap=chunk_overlap)
        
        if not chunks:
            print(f"  ⚠️  No chunks created for: {file_path}")
            return 0
        
        # Initialize semantic store
        data_dir = get_data_dir()
        index_path = os.path.join(data_dir, "semantic_index")
        semantic_store = SemanticStore(index_path=index_path)
        
        # Ingest document (handles chunking internally)
        chunk_ids = semantic_store.add_document(
            content=content,
            metadata=metadata,
            chunk_size=chunk_size,
            chunk_overlap=chunk_overlap
        )
        
        chunks_ingested = len(chunk_ids) if chunk_ids else 0
        print(f"  ✅ Ingested {chunks_ingested} chunks from {file_path}")
        return chunks_ingested
        
    except Exception as e:
        print(f"  ❌ Error ingesting {file_path}: {e}")
        return 0

def main():
    """Main function to ingest semantic memory."""
    print("🚀 Starting Semantic Memory Ingestion...")
    print("=" * 60)
    
    # Files to ingest (key documentation and code)
    files_to_ingest = [
        # Core Documentation
        ("/home/dietpi/synapse/README.md", "doc"),
        ("/home/dietpi/synapse/AGENTS.md", "doc"),
        ("/home/dietpi/synapse/MEMORY_SYSTEM_QUICK_REFERENCE.md", "doc"),
        ("/home/dietpi/synapse/docs/STRUCTURE.md", "doc"),
        
        # Core RAG Modules
        ("/home/dietpi/synapse/rag/__init__.py", "code"),
        ("/home/dietpi/synapse/rag/orchestrator.py", "code"),
        ("/home/dietpi/synapse/rag/memory_store.py", "code"),
        ("/home/dietpi/synapse/rag/semantic_store.py", "code"),
        ("/home/dietpi/synapse/rag/ingest.py", "code"),
        ("/home/dietpi/synapse/rag/bulk_ingest.py", "code"),
        ("/home/dietpi/synapse/rag/embedding.py", "code"),
        ("/home/dietpi/synapse/rag/vectorstore.py", "code"),
        ("/home/dietpi/synapse/rag/retriever.py", "code"),
        ("/home/dietpi/synapse/mcp_server/rag_server.py", "code"),
        
        # Configuration
        ("/home/dietpi/synapse/configs/rag_config.json", "code"),
    ]
    
    total_chunks = 0
    files_ingested = 0
    
    for file_path, source_type in files_to_ingest:
        print(f"\n📄 Processing: {file_path}")
        chunks = ingest_file_to_semantic_store(file_path, source_type)
        if chunks > 0:
            total_chunks += chunks
            files_ingested += 1
    
    print("\n" + "=" * 60)
    print(f"✅ Ingestion Complete!")
    print(f"   Files processed: {len(files_to_ingest)}")
    print(f"   Files successfully ingested: {files_ingested}")
    print(f"   Total chunks created: {total_chunks}")
    print("=" * 60)
    
    return 0 if total_chunks > 0 else 1

if __name__ == "__main__":
    sys.exit(main())
