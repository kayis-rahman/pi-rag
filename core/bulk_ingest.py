"""
Bulk Document Ingestion - Ingest entire directories.
"""

import os
import argparse
from typing import List, Dict, Any, Optional, Set
from pathlib import Path

from .ingest import ingest_file


# Supported file extensions
SUPPORTED_EXTENSIONS: Set[str] = {
    # Code files
    '.py', '.js', '.ts', '.jsx', '.tsx', '.java', '.cpp', '.c', '.h',
    '.hpp', '.cs', '.go', '.rs', '.rb', '.php', '.swift', '.kt', '.scala',
    '.sh', '.bash', '.zsh', '.fish',
    
    # Config files
    '.json', '.yaml', '.yml', '.toml', '.ini', '.cfg', '.conf',
    '.env', '.env.example',
    
    # Documentation
    '.md', '.mdx', '.txt', '.rst', '.adoc',
    
    # Web files
    '.html', '.htm', '.css', '.scss', '.sass', '.less',
    
    # Data files
    '.xml', '.csv',
    
    # SQL
    '.sql',
}

# Directories to skip
SKIP_DIRS: Set[str] = {
    '.git', '.svn', '.hg', '__pycache__', 'node_modules', '.venv', 'venv',
    'env', '.env', 'dist', 'build', '.next', '.nuxt', 'target', 'out',
    '.idea', '.vscode', '.pytest_cache', '.mypy_cache', 'coverage',
    'htmlcov', '.tox', 'eggs', '*.egg-info', '.eggs',
}


def should_process_file(file_path: Path, extensions: Optional[Set[str]] = None) -> bool:
    """Check if a file should be processed."""
    ext = file_path.suffix.lower()
    allowed = extensions or SUPPORTED_EXTENSIONS
    return ext in allowed


def should_skip_dir(dir_name: str) -> bool:
    """Check if a directory should be skipped."""
    return dir_name in SKIP_DIRS or dir_name.startswith('.')


def ingest_directory(
    directory: str,
    chunk_size: int = 500,
    chunk_overlap: int = 50,
    extensions: Optional[Set[str]] = None,
    metadata: Optional[Dict[str, Any]] = None,
    recursive: bool = True,
    config_path: str = "./configs/synapse_config.json"
) -> Dict[str, Any]:
    """
    Ingest all supported files from a directory.
    
    Args:
        directory: Path to directory
        chunk_size: Size of text chunks
        chunk_overlap: Overlap between chunks
        extensions: Set of allowed extensions (default: SUPPORTED_EXTENSIONS)
        metadata: Additional metadata for all files
        recursive: Whether to recurse into subdirectories
        config_path: Path to RAG config
        
    Returns:
        Dict with statistics about ingestion
    """
    dir_path = Path(directory)
    
    if not dir_path.exists():
        raise FileNotFoundError(f"Directory not found: {directory}")
    
    if not dir_path.is_dir():
        raise ValueError(f"Not a directory: {directory}")
    
    stats = {
        "total_files": 0,
        "processed_files": 0,
        "total_chunks": 0,
        "skipped_files": [],
        "errors": []
    }
    
    # Walk directory
    if recursive:
        file_iter = dir_path.rglob('*')
    else:
        file_iter = dir_path.glob('*')
    
    for file_path in file_iter:
        # Skip directories
        if file_path.is_dir():
            continue
        
        # Check if parent dir should be skipped
        skip = False
        for parent in file_path.parents:
            if should_skip_dir(parent.name):
                skip = True
                break
        
        if skip:
            continue
        
        stats["total_files"] += 1
        
        # Check if file should be processed
        if not should_process_file(file_path, extensions):
            stats["skipped_files"].append(str(file_path))
            continue
        
        # Prepare file metadata
        file_metadata = {
            "directory": str(dir_path.absolute()),
            "relative_path": str(file_path.relative_to(dir_path))
        }
        
        if metadata:
            file_metadata.update(metadata)
        
        # Ingest file
        try:
            chunks = ingest_file(
                str(file_path),
                chunk_size=chunk_size,
                chunk_overlap=chunk_overlap,
                metadata=file_metadata,
                config_path=config_path
            )
            stats["processed_files"] += 1
            stats["total_chunks"] += chunks
        except Exception as e:
            stats["errors"].append({
                "file": str(file_path),
                "error": str(e)
            })
    
    return stats


def main():
    """CLI entry point for bulk ingestion."""
    parser = argparse.ArgumentParser(
        description="Bulk ingest documents into RAG index"
    )
    parser.add_argument(
        "directory",
        help="Directory to ingest"
    )
    parser.add_argument(
        "--chunk-size", "-c",
        type=int,
        default=500,
        help="Chunk size in characters (default: 500)"
    )
    parser.add_argument(
        "--chunk-overlap", "-o",
        type=int,
        default=50,
        help="Chunk overlap in characters (default: 50)"
    )
    parser.add_argument(
        "--extensions", "-e",
        nargs="+",
        help="File extensions to process (default: all supported)"
    )
    parser.add_argument(
        "--no-recursive", "-n",
        action="store_true",
        help="Don't recurse into subdirectories"
    )
    parser.add_argument(
        "--tags", "-t",
        help="Comma-separated key:value tags to add as metadata"
    )
    parser.add_argument(
        "--config", "-f",
        default="./configs/synapse_config.json",
        help="Path to RAG config file"
    )
    
    args = parser.parse_args()
    
    # Parse extensions
    extensions = None
    if args.extensions:
        extensions = {e if e.startswith('.') else f'.{e}' for e in args.extensions}
    
    # Parse tags
    metadata = {}
    if args.tags:
        for tag in args.tags.split(','):
            if ':' in tag:
                key, value = tag.split(':', 1)
                metadata[key.strip()] = value.strip()
    
    print(f"Ingesting directory: {args.directory}")
    print(f"  Chunk size: {args.chunk_size}")
    print(f"  Chunk overlap: {args.chunk_overlap}")
    print(f"  Recursive: {not args.no_recursive}")
    if extensions:
        print(f"  Extensions: {extensions}")
    if metadata:
        print(f"  Metadata: {metadata}")
    print()
    
    try:
        stats = ingest_directory(
            args.directory,
            chunk_size=args.chunk_size,
            chunk_overlap=args.chunk_overlap,
            extensions=extensions,
            metadata=metadata,
            recursive=not args.no_recursive,
            config_path=args.config
        )
        
        print("\n" + "=" * 50)
        print("Ingestion Complete")
        print("=" * 50)
        print(f"Total files found: {stats['total_files']}")
        print(f"Files processed: {stats['processed_files']}")
        print(f"Total chunks created: {stats['total_chunks']}")
        print(f"Files skipped: {len(stats['skipped_files'])}")
        
        if stats["errors"]:
            print(f"\nErrors ({len(stats['errors'])}):")
            for error in stats["errors"][:10]:
                print(f"  - {error['file']}: {error['error']}")
            if len(stats["errors"]) > 10:
                print(f"  ... and {len(stats['errors']) - 10} more")
        
    except Exception as e:
        print(f"Error: {e}")
        return 1
    
    return 0


if __name__ == "__main__":
    exit(main())
