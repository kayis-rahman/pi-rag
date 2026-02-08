#!/usr/bin/env python3
"""
Bulk Injection Script with .gitignore Support

Injects all project files via local file path ingestion mode.
Features:
- .gitignore pattern parsing
- Custom exclusion patterns
- Dry-run mode
- Incremental ingestion with checksum verification
- File type filtering
- Retry file for failed ingestions
- Rich progress bar and logging

Usage:
    python bulk_inject_with_gitignore.py [options]

Examples:
    # Basic usage
    python bulk_inject_with_gitignore.py

    # Dry-run preview
    python bulk_inject_with_gitignore.py --dry-run

    # Different project
    python bulk_inject_with_gitignore.py --project-id myapp --root-dir /path/to/project

    # Filter by file type
    python bulk_inject_with_gitignore.py --file-type code --file-type doc

    # Custom exclusions only
    python bulk_inject_with_gitignore.py --no-gitignore --exclude "*.log"
"""

import argparse
import hashlib
import json
import logging
import os
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple, Any

# Rich imports for progress bar and logging
from rich.console import Console
from rich.logging import RichHandler
from rich.progress import Progress, SpinnerColumn, BarColumn, TextColumn, TimeRemainingColumn

# Setup logging with Rich
console = Console()
logging.basicConfig(
    level=logging.INFO,
    format="%(message)s",  # Rich adds its own formatting
    handlers=[RichHandler(console=console, rich_tracebacks=True)],
    force=True
)
logger = logging.getLogger(__name__)

# Add project root to path for imports
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

try:
    from core import SemanticStore, get_semantic_store
    from core.semantic_ingest import SemanticIngestor, get_semantic_ingestor
except ImportError as e:
    logger.error(f"Failed to import RAG modules: {e}")
    logger.error("Make sure you're running from SYNAPSE project directory")
    sys.exit(1)


# ============================================================================
# Configuration
# ============================================================================

class BulkInjectConfig:
    """Configuration for bulk injection."""
    def __init__(self):
        self.project_id: str = "SYNAPSE"
        self.root_dir: str = "."
        self.chunk_size: int = 500
        self.chunk_overlap: int = 50
        self.include_gitignore: bool = True
        self.custom_exclusions: List[str] = []
        self.file_types: Optional[List[str]] = None
        self.dry_run: bool = False
        self.incremental: bool = True
        self.config_path: str = "./configs/rag_config.json"
        self.verbose: bool = False


# ============================================================================
# Supported Extensions and File Types
# ============================================================================

FILE_TYPE_MAP = {
    'code': [
        '.py', '.js', '.ts', '.jsx', '.tsx', '.java', '.cpp', '.c', '.h',
        '.hpp', '.cs', '.go', '.rs', '.rb', '.php', '.swift', '.kt', '.scala',
        '.dart', '.lua', '.r', '.m', '.mm', '.pl', '.pm', '.sh', '.bash',
        '.zsh', '.fish', '.ps1', '.bat', '.cmd', '.groovy', '.kt', '.kts',
        '.fs', '.fsx', '.ex', '.exs', '.erl', '.hrl', '.elm', '.purs'
    ],
    'config': [
        '.json', '.yaml', '.yml', '.toml', '.ini', '.cfg', '.conf',
        '.env', '.env.example', '.properties', '.xml', '.config'
    ],
    'doc': [
        '.md', '.mdx', '.txt', '.rst', '.adoc', '.tex', '.pdf', '.docx',
        '.doc', '.wiki'
    ],
    'web': [
        '.html', '.htm', '.css', '.scss', '.sass', '.less', '.styl', '.vue',
        '.svelte'
    ],
    'data': [
        '.csv', '.tsv', '.sql', '.parquet', '.avro'
    ],
    'devops': [
        'Dockerfile', 'dockerfile', '.dockerignore', 'Makefile', 'makefile',
        '.gitignore', '.gitattributes', '.editorconfig', 'Jenkinsfile',
        '.gitlab-ci.yml', '.travis.yml', 'azure-pipelines.yml', 'cloudbuild.yaml'
    ],
}

SUPPORTED_EXTENSIONS = set()
for extensions in FILE_TYPE_MAP.values():
    SUPPORTED_EXTENSIONS.update(extensions)

SKIP_DIRS = {
    '.git', '.svn', '.hg', '__pycache__', 'node_modules', '.venv', 'venv',
    'env', '.env', 'dist', 'build', '.next', '.nuxt', 'target', 'out',
    '.idea', '.vscode', '.pytest_cache', '.mypy_cache', 'coverage',
    'htmlcov', '.tox', 'eggs', '*.egg-info', '.eggs', '.mypy_cache',
    '.gradle', '.cargo', '.npm', '.yarn', 'vendor', 'bower_components'
}


# ============================================================================
# Gitignore Pattern Parser
# ============================================================================

class GitignoreParser:
    """Parse and match .gitignore patterns."""

    def __init__(self, gitignore_path: Optional[str] = None, custom_patterns: List[str] = None):
        self.patterns: List[Dict[str, Any]] = []
        self.negation_patterns: List[str] = []

        if gitignore_path and os.path.exists(gitignore_path):
            self._parse_gitignore(gitignore_path)

        if custom_patterns:
            self._parse_custom_patterns(custom_patterns)

        logger.info(f"Loaded {len(self.patterns)} exclusion patterns, "
                   f"{len(self.negation_patterns)} negation patterns")

    def _parse_gitignore(self, path: str):
        """Parse .gitignore file."""
        try:
            with open(path, 'r') as f:
                for line_num, line in enumerate(f, 1):
                    line = line.strip()

                    # Skip comments and empty lines
                    if not line or line.startswith('#'):
                        continue

                    # Handle negation patterns
                    if line.startswith('!'):
                        pattern = line[1:]
                        self.negation_patterns.append(pattern)
                        continue

                    # Normalize pattern
                    pattern_info = self._normalize_pattern(line)
                    if pattern_info:
                        self.patterns.append(pattern_info)
        except Exception as e:
            logger.warning(f"Error reading .gitignore: {e}")

    def _parse_custom_patterns(self, patterns: List[str]):
        """Parse custom exclusion patterns."""
        for pattern in patterns:
            if pattern.startswith('!'):
                # Remove negation and add to patterns
                self.negation_patterns.append(pattern[1:])
            else:
                pattern_info = self._normalize_pattern(pattern)
                if pattern_info:
                    self.patterns.append(pattern_info)

    def _normalize_pattern(self, pattern: str) -> Optional[Dict[str, Any]]:
        """Normalize a gitignore pattern."""
        pattern = pattern.rstrip('/')
        is_dir = pattern.endswith('/')
        pattern = pattern.rstrip('/')

        # Handle patterns starting with /
        if pattern.startswith('/'):
            pattern = pattern[1:]
            anchored = True
        else:
            anchored = False

        # Handle ** patterns
        has_double_star = '**' in pattern

        return {
            'pattern': pattern,
            'is_dir': is_dir,
            'anchored': anchored,
            'has_double_star': has_double_star,
            'wildcard': '*' in pattern and not has_double_star
        }

    def matches(self, file_path: Path, relative_path: str) -> bool:
        """Check if file matches any exclusion pattern.

        Returns True if file should be excluded.
        """
        # Check negation patterns first (they override)
        for neg_pattern in self.negation_patterns:
            if self._match_pattern(file_path, relative_path, neg_pattern):
                return False  # Not excluded (negated)

        # Check exclusion patterns
        for pattern_info in self.patterns:
            if self._match_pattern_info(file_path, relative_path, pattern_info):
                return True  # Excluded

        return False  # Not excluded

    def _match_pattern_info(self, file_path: Path, relative_path: str, pattern_info: Dict[str, Any]) -> bool:
        """Match against a normalized pattern info."""
        return self._match_pattern(file_path, relative_path, pattern_info['pattern'],
                                   anchored=pattern_info['anchored'],
                                   is_dir=pattern_info['is_dir'],
                                   has_double_star=pattern_info['has_double_star'],
                                   wildcard=pattern_info['wildcard'])

    def _match_pattern(self, file_path: Path, relative_path: str, pattern: str,
                      anchored: bool = False, is_dir: bool = False,
                      has_double_star: bool = False, wildcard: bool = False) -> bool:
        """Match a single pattern against file path."""

        # Directory pattern
        if is_dir and not file_path.is_dir():
            return False

        # Exact match
        if pattern == file_path.name or pattern == relative_path:
            return True

        # Anchored pattern (from root)
        if anchored:
            path_parts = relative_path.split('/')
            for i, part in enumerate(path_parts):
                if self._glob_match(pattern, part):
                    # If pattern matches first part and file is at root level
                    if i == 0 and len(path_parts) == 1:
                        return True
                    # If pattern is a directory name in path
                    if pattern in path_parts:
                        return True
        else:
            # Non-anchored - check any part of path
            path_parts = relative_path.split('/')
            if has_double_star:
                # ** matches any number of directories
                base_parts = pattern.split('**/')
                if len(base_parts) == 2:
                    start, end = base_parts
                    start_match = not start or self._glob_match(start, path_parts[0])
                    end_match = not end or self._glob_match(end, path_parts[-1])
                    return start_match and end_match

            # Wildcard matching
            for part in path_parts:
                if self._glob_match(pattern, part):
                    return True

            # Also check filename
            if self._glob_match(pattern, file_path.name):
                return True

        return False

    def _glob_match(self, pattern: str, text: str) -> bool:
        """Simple glob pattern matching."""
        if pattern == '*':
            return True
        if not ('*' in pattern or '?' in pattern):
            return pattern == text

        # Convert glob to regex
        import re
        regex = ''
        i = 0
        while i < len(pattern):
            char = pattern[i]
            if char == '*':
                regex += '.*'
            elif char == '?':
                regex += '.'
            elif char in '.^$+()[]{}|\\':
                regex += '\\' + char
            else:
                regex += char
            i += 1

        return re.fullmatch(regex, text) is not None


# ============================================================================
# File Scanner
# ============================================================================

class FileScanner:
    """Discover and filter files."""

    def __init__(self, root_dir: str, gitignore: GitignoreParser):
        self.root_dir = Path(root_dir).resolve()
        self.gitignore = gitignore
        self.supported_extensions = SUPPORTED_EXTENSIONS
        self.skip_dirs = SKIP_DIRS

    def scan_files(self, file_type_filter: Optional[List[str]] = None) -> List[Tuple[Path, str]]:
        """Scan and filter files.

        Returns:
            List of (file_path, relative_path) tuples
        """
        files: List[Tuple[Path, str]] = []

        logger.info(f"Scanning directory: {self.root_dir}")

        for file_path in self.root_dir.rglob('*'):
            # Skip directories
            if file_path.is_dir():
                # Check if should skip this directory
                if file_path.name in self.skip_dirs:
                    # Modify rglob to skip this directory
                    # This is handled by checking relative path below
                    pass
                continue

            # Get relative path
            try:
                relative_path = str(file_path.relative_to(self.root_dir))
            except ValueError:
                continue

            # Check if any parent directory is in skip_dirs
            skip = False
            for parent in reversed(file_path.parents):
                if parent.name in self.skip_dirs:
                    skip = True
                    break

            if skip:
                continue

            # Check extension
            if file_path.suffix.lower() not in self.supported_extensions:
                continue

            # Check gitignore patterns
            if self.gitignore.matches(file_path, relative_path):
                continue

            # Filter by file type if specified
            if file_type_filter:
                file_type = self.get_file_type(file_path)
                if file_type not in file_type_filter:
                    continue

            files.append((file_path, relative_path))

        logger.info(f"Found {len(files)} files to process")
        return files

    @staticmethod
    def get_file_type(file_path: Path) -> str:
        """Determine file type from extension."""
        ext = file_path.suffix.lower()
        for ftype, extensions in FILE_TYPE_MAP.items():
            if ext in extensions:
                return ftype
        return 'other'


# ============================================================================
# Incremental Ingestor
# ============================================================================

class IncrementalIngestor:
    """Handle incremental ingestion with checksum verification."""

    RETRY_FILE = "failed_ingestions.json"

    def __init__(self, semantic_store: SemanticStore, project_id: str):
        self.store = semantic_store
        self.project_id = project_id
        self.file_checksums: Dict[str, str] = {}
        self.failed_files: List[Dict[str, str]] = []
        self._load_existing_checksums()
        self._load_failed_files()

    def _calculate_checksum(self, file_path: str) -> str:
        """Calculate MD5 checksum of file content."""
        try:
            with open(file_path, 'rb') as f:
                return hashlib.md5(f.read()).hexdigest()
        except Exception as e:
            logger.warning(f"Failed to calculate checksum for {file_path}: {e}")
            return ""

    def _get_document_id(self, file_path: str) -> str:
        """Generate document ID from file path."""
        doc_hash = hashlib.md5(file_path.encode()).hexdigest()[:16]
        return f"doc_{doc_hash}"

    def should_skip_file(self, file_path: str, file_checksum: str) -> Tuple[bool, str]:
        """Check if file should be skipped (already ingested with same content).

        Returns:
            (skip, reason) tuple
        """
        doc_id = self._get_document_id(file_path)

        # Check if document exists
        if doc_id not in self.store.document_ids:
            return (False, "New document")

        # Check if checksum matches
        existing_checksum = self.file_checksums.get(file_path)
        if existing_checksum == file_checksum:
            return (True, "Content unchanged (checksum match)")

        return (False, "Content changed (checksum mismatch)")

    def record_ingestion(self, file_path: str, checksum: str, chunk_ids: List[str]):
        """Record that file was ingested."""
        self.file_checksums[file_path] = checksum
        self._save_checksums()

    def record_failure(self, file_path: str, error: str):
        """Record a failed ingestion."""
        failure_record = {
            "file_path": file_path,
            "error": error,
            "timestamp": datetime.utcnow().isoformat()
        }
        self.failed_files.append(failure_record)
        self._save_failed_files()

    def _load_existing_checksums(self):
        """Load checksums from disk."""
        checksums_file = os.path.join(self.store.index_path, "checksums.json")
        if os.path.exists(checksums_file):
            try:
                with open(checksums_file, 'r') as f:
                    data = json.load(f)
                    # Get project-specific checksums if available
                    self.file_checksums = data.get(self.project_id, {})
                logger.info(f"Loaded {len(self.file_checksums)} existing checksums")
            except Exception as e:
                logger.warning(f"Failed to load checksums: {e}")

    def _save_checksums(self):
        """Save checksums to disk."""
        checksums_file = os.path.join(self.store.index_path, "checksums.json")
        try:
            # Load existing data
            if os.path.exists(checksums_file):
                with open(checksums_file, 'r') as f:
                    all_data = json.load(f)
            else:
                all_data = {}

            # Update with project-specific checksums
            all_data[self.project_id] = self.file_checksums

            # Save
            with open(checksums_file, 'w') as f:
                json.dump(all_data, f, indent=2)
        except Exception as e:
            logger.warning(f"Failed to save checksums: {e}")

    def _load_failed_files(self):
        """Load previously failed files."""
        retry_file = os.path.join(self.store.index_path, self.RETRY_FILE)
        if os.path.exists(retry_file):
            try:
                with open(retry_file, 'r') as f:
                    self.failed_files = json.load(f)
                logger.info(f"Loaded {len(self.failed_files)} previously failed files")
            except Exception as e:
                logger.warning(f"Failed to load retry file: {e}")

    def _save_failed_files(self):
        """Save failed files to retry file."""
        retry_file = os.path.join(self.store.index_path, self.RETRY_FILE)
        try:
            with open(retry_file, 'w') as f:
                json.dump(self.failed_files, f, indent=2)
        except Exception as e:
            logger.warning(f"Failed to save retry file: {e}")

    def get_retry_files(self) -> List[str]:
        """Get list of previously failed file paths."""
        return [f["file_path"] for f in self.failed_files if os.path.exists(f["file_path"])]

    def clear_failure(self, file_path: str):
        """Clear a file from failed list after successful retry."""
        self.failed_files = [f for f in self.failed_files if f["file_path"] != file_path]
        self._save_failed_files()


# ============================================================================
# Main Bulk Injector
# ============================================================================

class BulkInjector:
    """Main bulk injection orchestrator."""

    def __init__(self, config: BulkInjectConfig):
        self.config = config

        # Resolve root directory
        self.root_dir = Path(config.root_dir).resolve()
        if not self.root_dir.exists():
            raise FileNotFoundError(f"Root directory not found: {config.root_dir}")

        # Initialize components
        self.gitignore = None
        if config.include_gitignore:
            gitignore_path = os.path.join(self.root_dir, '.gitignore')
            self.gitignore = GitignoreParser(
                gitignore_path if os.path.exists(gitignore_path) else None,
                config.custom_exclusions
            )
        elif config.custom_exclusions:
            self.gitignore = GitignoreParser(None, config.custom_exclusions)

        self.scanner = FileScanner(str(self.root_dir), self.gitignore or GitignoreParser())

        # Initialize semantic ingestor
        self.semantic_ingestor = get_semantic_ingestor()
        self.incremental = IncrementalIngestor(
            self.semantic_ingestor.semantic_store,
            config.project_id
        )

        # Statistics
        self.stats = {
            "total_found": 0,
            "excluded": 0,
            "new": 0,
            "updated": 0,
            "skipped": 0,
            "retried": 0,
            "errors": 0,
            "total_chunks": 0,
            "errors_list": []
        }

    def run(self):
        """Execute bulk injection."""
        start_time = datetime.now()

        print("=" * 70)
        if self.config.dry_run:
            print("BULK INJECTION - DRY RUN")
        else:
            print("BULK INJECTION STARTED")
        print("=" * 70)
        print(f"Project: {self.config.project_id}")
        print(f"Root: {self.root_dir}")
        print(f"Incremental mode: {'Enabled' if self.config.incremental else 'Disabled'}")
        print(f".gitignore parsing: {'Enabled' if self.config.include_gitignore else 'Disabled'}")
        if self.config.file_types:
            print(f"File type filter: {', '.join(self.config.file_types)}")
        print()

        # Add retry files to scan
        retry_files = set(self.incremental.get_retry_files())

        # Scan files
        logger.info("Scanning files...")
        files = self.scanner.scan_files(self.config.file_types)
        self.stats["total_found"] = len(files)

        # Add retry files
        for retry_file in retry_files:
            retry_path = Path(retry_file)
            if retry_path.exists():
                try:
                    rel_path = str(retry_path.relative_to(self.root_dir))
                    # Add if not already in list
                    if not any(f[0] == retry_path for f in files):
                        files.append((retry_path, rel_path))
                        self.stats["total_found"] += 1
                except ValueError:
                    pass

        # Process files with Rich progress bar
        logger.info("Processing files...")
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            BarColumn(bar_width=40),
            TextColumn("[progress.percentage]{task.percentage:>3.0f}%"),
            TextColumn("({task.completed}/{task.total})"),
            TimeRemainingColumn(),
            console=console,
            refresh_per_second=10
        ) as progress:
            task = progress.add_task("[cyan]Processing files...", total=len(files))

            for file_path, relative_path in files:
                self._process_file(file_path, relative_path)

                # Update progress bar with current file name
                file_status = "🆕" if self.stats['new'] > self.stats['updated'] else "🔄"
                progress.update(task, advance=1, description=f"[cyan]Processing {file_path.name}")

        # Get store stats
        store_stats = self.semantic_ingestor.semantic_store.get_stats()

        # Print summary
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()

        print()
        print("=" * 70)
        if self.config.dry_run:
            print("BULK INJECTION COMPLETE (DRY RUN)")
        else:
            print("BULK INJECTION COMPLETE")
        print("=" * 70)
        print(f"Total files found: {self.stats['total_found']}")
        if self.gitignore:
            print(f"Excluded by patterns: {self.stats['excluded']} (estimated)")
        print(f"Files processed: {self.stats['new'] + self.stats['updated'] + self.stats['skipped'] + self.stats['retried']}")
        print(f"  - New documents: {self.stats['new']}")
        print(f"  - Updated documents: {self.stats['updated']}")
        print(f"  - Skipped (unchanged): {self.stats['skipped']}")
        print(f"  - Retried from failures: {self.stats['retried']}")
        print(f"Total chunks created: {self.stats['total_chunks']}")
        print(f"Errors: {self.stats['errors']}")
        print(f"Time: {int(duration // 60)}m {int(duration % 60)}s")
        print()

        # Show errors if any
        if self.stats['errors']:
            print("=" * 70)
            print("ERRORS:")
            print("=" * 70)
            for i, error in enumerate(self.stats['errors_list'][:10], 1):
                print(f"{i}. {error['file']}")
                print(f"   Error: {error['error']}")
            if len(self.stats['errors_list']) > 10:
                print(f"... and {len(self.stats['errors_list']) - 10} more errors")
            print()
            print(f"Failed files saved to retry list: {len(self.incremental.failed_files)}")
            print("They will be retried on next run.")
            print()

        # Store stats
        if self.config.dry_run:
            print("NO FILES WERE INGESTED (dry-run mode)")
            print("To ingest, run without --dry-run flag")
        elif self.stats['errors'] == 0:
            print("✅ ALL FILES INGESTED SUCCESSFULLY!")
        else:
            print(f"⚠️  INGESTION COMPLETE WITH {self.stats['errors']} ERRORS")
        print("=" * 70)

        return 0 if self.stats['errors'] == 0 else 1

    def _process_file(self, file_path: Path, relative_path: str):
        """Process a single file."""
        try:
            # Calculate checksum
            checksum = self.incremental._calculate_checksum(str(file_path))
            if not checksum:
                self.stats['errors'] += 1
                error_msg = f"Failed to calculate checksum"
                self.stats['errors_list'].append({'file': str(file_path), 'error': error_msg})
                self.incremental.record_failure(str(file_path), error_msg)
                return

            # Check if should skip (incremental mode)
            if self.config.incremental:
                skip, reason = self.incremental.should_skip_file(str(file_path), checksum)
                if skip:
                    self.stats['skipped'] += 1
                    if self.config.verbose:
                        logger.info(f"Skipping {relative_path}: {reason}")
                    return
                else:
                    # Check if it's a retry
                    if str(file_path) in self.incremental.get_retry_files():
                        self.stats['retried'] += 1
                    elif "Content changed" in reason:
                        self.stats['updated'] += 1
                    else:
                        self.stats['new'] += 1
            else:
                self.stats['new'] += 1

            if self.config.dry_run:
                return

            # Generate metadata
            metadata = self._generate_metadata(file_path, relative_path)

            # Ingest file
            try:
                chunk_ids = self.semantic_ingestor.ingest_file(
                    file_path=str(file_path),
                    metadata=metadata,
                    chunk_size=self.config.chunk_size,
                    chunk_overlap=self.config.chunk_overlap
                )

                self.stats['total_chunks'] += len(chunk_ids)

                # Record ingestion
                self.incremental.record_ingestion(str(file_path), checksum, chunk_ids)

                # Clear from retry list if successful
                self.incremental.clear_failure(str(file_path))

                if self.config.verbose:
                    logger.info(f"Ingested {relative_path}: {len(chunk_ids)} chunks")

            except Exception as e:
                self.stats['errors'] += 1
                error_msg = str(e)
                self.stats['errors_list'].append({'file': str(file_path), 'error': error_msg})
                self.incremental.record_failure(str(file_path), error_msg)
                logger.warning(f"Failed to ingest {relative_path}: {e}")

        except Exception as e:
            self.stats['errors'] += 1
            error_msg = str(e)
            self.stats['errors_list'].append({'file': str(file_path), 'error': error_msg})
            self.incremental.record_failure(str(file_path), error_msg)
            logger.warning(f"Error processing {relative_path}: {e}")

    def _generate_metadata(self, file_path: Path, relative_path: str) -> Dict[str, Any]:
        """Generate metadata for a file."""
        file_type = self.scanner.get_file_type(file_path)

        metadata = {
            "source": str(file_path),
            "type": file_type,
            "filename": file_path.name,
            "relative_path": relative_path,
            "extension": file_path.suffix.lower(),
            "project_id": self.config.project_id,
            "ingested_at": datetime.utcnow().isoformat()
        }

        return metadata


# ============================================================================
# Command-Line Interface
# ============================================================================

def parse_args():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(
        description="Bulk inject project files with .gitignore support",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Basic usage
  %(prog)s

  # Dry-run preview
  %(prog)s --dry-run

  # Different project
  %(prog)s --project-id myapp --root-dir /path/to/project

  # Filter by file type
  %(prog)s --file-type code --file-type doc

  # Custom exclusions only
  %(prog)s --no-gitignore --exclude "*.log"

  # Force full re-ingest
  %(prog)s --no-incremental
        """
    )

    parser.add_argument(
        "--project-id",
        default="SYNAPSE",
        help="Project ID for metadata (default: SYNAPSE)"
    )
    parser.add_argument(
        "--root-dir",
        default=".",
        help="Root directory to scan (default: script directory)"
    )
    parser.add_argument(
        "--chunk-size",
        type=int,
        default=500,
        help="Chunk size in characters (default: 500)"
    )
    parser.add_argument(
        "--chunk-overlap",
        type=int,
        default=50,
        help="Chunk overlap in characters (default: 50)"
    )
    parser.add_argument(
        "--no-gitignore",
        action="store_true",
        help="Disable .gitignore parsing"
    )
    parser.add_argument(
        "--exclude",
        action="append",
        default=[],
        help="Custom exclusion patterns (can be used multiple times)"
    )
    parser.add_argument(
        "--file-type",
        action="append",
        choices=["code", "config", "doc", "web", "data", "devops"],
        help="Filter by file type (can be used multiple times)"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Dry-run mode - show what would be ingested"
    )
    parser.add_argument(
        "--no-incremental",
        action="store_true",
        help="Disable incremental mode (force re-ingest all)"
    )
    parser.add_argument(
        "--config",
        default="./configs/rag_config.json",
        help="Path to RAG config file (default: ./configs/rag_config.json)"
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Verbose output"
    )

    return parser.parse_args()


def main():
    """Main entry point."""
    args = parse_args()

    # Build config
    config = BulkInjectConfig()
    config.project_id = args.project_id
    config.root_dir = args.root_dir
    config.chunk_size = args.chunk_size
    config.chunk_overlap = args.chunk_overlap
    config.include_gitignore = not args.no_gitignore
    config.custom_exclusions = args.exclude
    config.file_types = args.file_type
    config.dry_run = args.dry_run
    config.incremental = not args.no_incremental
    config.config_path = args.config
    config.verbose = args.verbose

    try:
        # Run injection
        injector = BulkInjector(config)
        return injector.run()
    except Exception as e:
        logger.error(f"Bulk injection failed: {e}", exc_info=True)
        return 1


if __name__ == "__main__":
    sys.exit(main())
