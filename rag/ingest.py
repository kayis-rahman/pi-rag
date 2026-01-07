"""
Document Ingestion - Single file ingestion with chunking.
"""

import os
import json
from typing import List, Dict, Any, Optional
from pathlib import Path

from .retriever import get_retriever
from .logger import get_logger
logger = get_logger(__name__)


def chunk_text(
    text: str,
    chunk_size: int = 500,
    chunk_overlap: int = 50
) -> List[str]:
    """
    Split text into overlapping chunks.
    
    Args:
        text: Text to split
        chunk_size: Target size of each chunk (in characters)
        chunk_overlap: Overlap between chunks
        
    Returns:
        List of text chunks
    """
    if not text:
        return []
    
    # Split by paragraphs first
    paragraphs = text.split('\n\n')
    
    chunks = []
    current_chunk = ""
    
    for para in paragraphs:
        para = para.strip()
        if not para:
            continue
        
        # If adding this paragraph exceeds chunk size
        if len(current_chunk) + len(para) + 2 > chunk_size:
            # Save current chunk if not empty
            if current_chunk:
                chunks.append(current_chunk.strip())
            
            # If paragraph itself is too long, split it
            if len(para) > chunk_size:
                # Split by sentences or fixed size
                words = para.split()
                current_chunk = ""
                for word in words:
                    if len(current_chunk) + len(word) + 1 > chunk_size:
                        if current_chunk:
                            chunks.append(current_chunk.strip())
                        current_chunk = word
                    else:
                        current_chunk = f"{current_chunk} {word}".strip()
            else:
                current_chunk = para
        else:
            current_chunk = f"{current_chunk}\n\n{para}".strip()
    
    # Don't forget the last chunk
    if current_chunk:
        chunks.append(current_chunk.strip())
    
    # Apply overlap
    if chunk_overlap > 0 and len(chunks) > 1:
        overlapped = []
        for i, chunk in enumerate(chunks):
            if i > 0:
                # Get overlap from previous chunk
                prev_chunk = chunks[i-1]
                overlap_text = prev_chunk[-chunk_overlap:] if len(prev_chunk) > chunk_overlap else prev_chunk
                chunk = f"...{overlap_text}...\n{chunk}"
            overlapped.append(chunk)
        chunks = overlapped
    
    return chunks


def read_file(file_path: str) -> str:
    """Read file content with encoding detection."""
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


def ingest_file(
    file_path: str,
    chunk_size: int = 500,
    chunk_overlap: int = 50,
    metadata: Optional[Dict[str, Any]] = None,
    config_path: str = "./configs/rag_config.json"
) -> int:
    """
    Ingest a single file into the RAG index.
    
    Args:
        file_path: Path to the file
        chunk_size: Size of text chunks
        chunk_overlap: Overlap between chunks
        metadata: Additional metadata to attach
        config_path: Path to RAG config
        
    Returns:
        Number of chunks ingested
    """
    path = Path(file_path)
    
    if not path.exists():
        raise FileNotFoundError(f"File not found: {file_path}")
    
    # Read file content
    content = read_file(str(path))
    
    if not content.strip():
        logger.warning(f"Empty file: {file_path}")
        return 0
    
    # Chunk the content
    chunks = chunk_text(content, chunk_size, chunk_overlap)
    
    if not chunks:
        return 0
    
    # Prepare metadata for each chunk
    base_metadata = {
        "source": str(path.absolute()),
        "filename": path.name,
        "extension": path.suffix.lower(),
    }
    
    if metadata:
        base_metadata.update(metadata)
    
    chunk_metadata = []
    for i, chunk in enumerate(chunks):
        meta = base_metadata.copy()
        meta["chunk_index"] = i
        meta["total_chunks"] = len(chunks)
        chunk_metadata.append(meta)
    
    # Add to index
    retriever = get_retriever(config_path)
    count = retriever.add_documents(chunks, chunk_metadata)
    
    logger.info(f"Ingested {count} chunks from {path.name}")
    return count


def ingest_text(
    text: str,
    source_name: str = "manual",
    chunk_size: int = 500,
    chunk_overlap: int = 50,
    metadata: Optional[Dict[str, Any]] = None,
    config_path: str = "./configs/rag_config.json"
) -> int:
    """
    Ingest raw text into the RAG index.
    
    Args:
        text: Text content to ingest
        source_name: Name for the source
        chunk_size: Size of text chunks
        chunk_overlap: Overlap between chunks
        metadata: Additional metadata
        config_path: Path to RAG config
        
    Returns:
        Number of chunks ingested
    """
    if not text.strip():
        return 0
    
    chunks = chunk_text(text, chunk_size, chunk_overlap)
    
    if not chunks:
        return 0
    
    base_metadata = {
        "source": source_name,
        "type": "text"
    }
    
    if metadata:
        base_metadata.update(metadata)
    
    chunk_metadata = []
    for i, chunk in enumerate(chunks):
        meta = base_metadata.copy()
        meta["chunk_index"] = i
        meta["total_chunks"] = len(chunks)
        chunk_metadata.append(meta)
    
    retriever = get_retriever(config_path)
    count = retriever.add_documents(chunks, chunk_metadata)
    
    logger.info(f"Ingested {count} chunks from {source_name}")
    return count


if __name__ == "__main__":
    import sys
    
    if len(sys.argv) < 2:
        # Keep usage as print (CLI help)
        print("Usage: python -m rag.ingest <file_path> [chunk_size] [chunk_overlap]")
        sys.exit(1)
    
    file_path = sys.argv[1]
    chunk_size = int(sys.argv[2]) if len(sys.argv) > 2 else 500
    chunk_overlap = int(sys.argv[3]) if len(sys.argv) > 3 else 50
    
    try:
        count = ingest_file(file_path, chunk_size, chunk_overlap)
        logger.info(f"Successfully ingested {count} chunks")
    except Exception as e:
        logger.error(f"Error: {e}")
        sys.exit(1)
