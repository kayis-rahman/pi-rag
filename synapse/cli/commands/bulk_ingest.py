"""
SYNAPSE CLI: Bulk Ingest Command

Bulk ingest documents into SYNAPSE knowledge base.
"""

import sys
import os
from pathlib import Path
import typer

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent))

# Change to synapse directory for proper imports
os.chdir(Path(__file__).parent.parent.parent.parent)

try:
    from scripts.bulk_ingest import main as bulk_ingest_main
except ImportError:
    bulk_ingest_main = None

app = typer.Typer(
    name="bulk-ingest",
    help="Bulk ingest documents into SYNAPSE knowledge base"
)


@app.command()
def bulk_ingest(
    path: Path = typer.Argument(
        ...,
        help="Directory path to ingest"
    ),
    project_id: str = typer.Option(
        "synapse",
        "--project-id", "-p",
        help="Project ID for storage"
    ),
    chunk_size: int = typer.Option(
        500,
        "--chunk-size", "-c",
        help="Chunk size for document splitting"
    ),
    dry_run: bool = typer.Option(
        False,
        "--dry-run", "-n",
        help="Show files to ingest without actually ingesting"
    ),
    exclude_patterns: str = typer.Option(
        "",
        "--exclude", "-e",
        help="Comma-separated patterns to exclude (e.g., '*.log,*.tmp')"
    )
):
    """
    Bulk ingest all documents from a directory into semantic memory.

    Examples:
        synapse bulk-ingest /path/to/docs
        synapse bulk-ingest /path/to/docs --dry-run
        synapse bulk-ingest /path/to/docs --project-id myproject
    """
    if bulk_ingest_main is None:
        print("❌ Error: bulk_ingest module not available")
        print("   Try: python3 scripts/bulk_ingest.py <directory>")
        raise SystemExit(1)

    # Verify path exists
    if not path.exists():
        print(f"❌ Error: Path does not exist: {path}")
        raise SystemExit(1)

    if not path.is_dir():
        print(f"❌ Error: Path is not a directory: {path}")
        raise SystemExit(1)

    print("🚀 Starting bulk ingestion...")
    print(f"  Path: {path}")
    print(f"  Project ID: {project_id}")
    print(f"  Chunk size: {chunk_size}")

    if dry_run:
        print("\n🔍 Dry run mode - showing files that would be ingested:")
        # Count files
        exclude_list = [p.strip() for p in exclude_patterns.split(",") if p.strip()]
        file_count = 0
        for root, dirs, files in os.walk(path):
            # Skip hidden directories
            dirs[:] = [d for d in dirs if not d.startswith('.')]
            for f in files:
                if f.startswith('.'):
                    continue
                # Check exclude patterns
                skip = False
                for pattern in exclude_list:
                    if pattern in f:
                        skip = True
                        break
                if not skip:
                    file_count += 1
        print(f"  Would ingest: {file_count} files")
        print("\n✅ Dry run complete")
        return

    # Build command arguments
    cmd_args = ["scripts/bulk_ingest.py"]

    # Add project ID if not default
    if project_id != "synapse":
        cmd_args.extend(["--project-id", project_id])

    # Add the path as root-dir
    cmd_args.extend(["--root-dir", str(path)])

    # Add chunk size if not default
    if chunk_size != 500:
        cmd_args.extend(["--chunk-size", str(chunk_size)])

    # Add exclude patterns
    if exclude_patterns:
        cmd_args.extend(["--exclude", exclude_patterns])

    # Run bulk ingest
    try:
        sys.argv = cmd_args
        bulk_ingest_main()
    except SystemExit:
        pass


if __name__ == "__main__":
    app()
