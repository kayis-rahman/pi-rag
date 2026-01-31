"""
SYNAPSE CLI: Models Management

Model download and management commands.
"""

import hashlib
import json
import time
import typer
from pathlib import Path
from typing import Optional

from rich.console import Console
from rich.progress import (
    Progress,
    SpinnerColumn,
    TextColumn,
    BarColumn,
    DownloadColumn,
    TransferSpeedColumn,
    TimeRemainingColumn,
    TaskID
)
from rich.table import Table

console = Console()


# Inline fallback registry (will be removed once registry is loaded from JSON)
AVAILABLE_MODELS = {
    "embedding": {
        "name": "bge-m3",
        "file": "bge-m3-q8_0.gguf",
        "size_mb": 730,
        "description": "BGE-M3 embedding model for semantic search",
        "huggingface": "BAAI/bge-m3/gguf/bge-m3-q8_0.gguf",
        "checksum": None
    },
    "chat": {
        "name": "gemma-3-1b",
        "file": "gemma-3-1b-it-UD-Q4_K_XL.gguf",
        "size_mb": 400,
        "description": "Gemma 3 1B chat model for local chat",
        "huggingface": "google/gemma-3-1b-it/gguf/gemma-3-1b-it-UD-Q4_K_XL.gguf",
        "checksum": None
    }
}


def load_models_registry() -> dict:
    """Load models registry from JSON file."""
    registry_path = Path(__file__).parent.parent.parent / "synapse" / "config" / "models.json"

    if not registry_path.exists():
        # Fall back to inline registry
        return AVAILABLE_MODELS

    try:
        with open(registry_path, 'r') as f:
            data = json.load(f)
            return data.get("models", AVAILABLE_MODELS)
    except Exception as e:
        console.print(f"[yellow]⚠️  Failed to load models registry: {e}[/yellow]")
        console.print("[yellow]   Using inline registry fallback[/yellow]")
        return AVAILABLE_MODELS


def save_models_registry(registry: dict) -> bool:
    """Save models registry to JSON file."""
    registry_path = Path(__file__).parent.parent.parent / "synapse" / "config" / "models.json"

    try:
        with open(registry_path, 'w') as f:
            json.dump({"models": registry}, f, indent=2)
        return True
    except Exception as e:
        console.print(f"[red]❌ Failed to save models registry: {e}[/red]")
        return False


# Load registry at module import time
MODELS_REGISTRY = load_models_registry()


def get_models_directory() -> Path:
    """Get models directory path."""
    import os
    # Try common locations
    locations = [
        Path("/app/models"),  # Docker
        Path("/opt/synapse/models"),  # Native install
        Path.home() / ".synapse" / "models",  # User home
        Path("~/.synapse/models").expanduser()
    ]

    for loc in locations:
        if loc.exists():
            return loc

    # Create in user home as fallback
    user_models = Path.home() / ".synapse" / "models"
    user_models.mkdir(parents=True, exist_ok=True)
    return user_models


def find_model_by_name_or_type(model_identifier: str) -> Optional[tuple[str, dict]]:
    """
    Find model in registry by type or by name.

    Args:
        model_identifier: Model type (e.g., "embedding") or model name (e.g., "bge-m3")

    Returns:
        Tuple of (model_type, model_info) if found, None otherwise
    """
    # First check if it's a type (direct key lookup)
    if model_identifier in MODELS_REGISTRY:
        return model_identifier, MODELS_REGISTRY[model_identifier]

    # Then check if it's a name (iterate through all models)
    for model_type, model_info in MODELS_REGISTRY.items():
        if model_info.get("name") == model_identifier:
            return model_type, model_info

    return None


def list_models():
    """List available and installed models with checksum status."""
    console.print("\n[cyan]📦 Available Models:[/cyan]")
    console.print("=" * 50)

    models_dir = get_models_directory()

    # Create table
    table = Table(title="Model Registry")
    table.add_column("Type", style="cyan", width=10)
    table.add_column("Name", style="white", width=15)
    table.add_column("Size", style="white", width=10)
    table.add_column("Installed", style="white", width=10)
    table.add_column("Checksum", style="white", width=20)

    for model_type, model_info in MODELS_REGISTRY.items():
        model_path = models_dir / model_info["file"]
        installed = model_path.exists()

        status = "[green]✓ Yes[/green]" if installed else "[red]✗ No[/red]"

        # Checksum status
        stored_checksum = model_info.get("checksum")
        if installed and stored_checksum:
            actual_checksum = compute_checksum(model_path)
            checksum_valid = actual_checksum == stored_checksum
            checksum_status = f"[green]✓ Valid[/green]" if checksum_valid else f"[red]✗ Invalid[/red]"
        elif installed:
            checksum_status = "[yellow]⚠️  Unknown[/yellow]"
        elif stored_checksum:
            checksum_status = f"[dim]N/A[/dim]"
        else:
            checksum_status = "[dim]N/A[/dim]"

        table.add_row(
            model_type.upper(),
            model_info['name'],
            f"{model_info['size_mb']} MB",
            status,
            checksum_status
        )

    console.print(table)
    console.print("\n[dim]Use 'synapse models download <type>' to install a model[/dim]")


def compute_checksum(file_path: Path) -> Optional[str]:
    """Compute SHA256 checksum of a file."""
    sha256_hash = hashlib.sha256()

    try:
        with open(file_path, "rb") as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
        return sha256_hash.hexdigest()
    except Exception as e:
        console.print(f"[red]❌ Failed to compute checksum: {e}[/red]")
        return None


def download_model(
    model_name: str,
    force: bool = False
) -> bool:
    """
    Download model from HuggingFace with progress, retry, and checksum verification.

    Args:
        model_name: Model type (e.g., "embedding") or model name (e.g., "bge-m3")
        force: Force re-download even if already exists

    Returns:
        True if download successful, False otherwise
    """
    # Check model exists in registry (by type or name)
    model_result = find_model_by_name_or_type(model_name)
    if model_result is None:
        # Build list of available model names
        available_names = [info.get("name", model_type) for model_type, info in MODELS_REGISTRY.items()]
        console.print(f"[red]❌ Unknown model: {model_name}[/red]")
        console.print(f"   Available models: {', '.join(MODELS_REGISTRY.keys())}")
        console.print(f"   Available by name: {', '.join(available_names)}")
        return False

    model_type, model_info = model_result
    models_dir = get_models_directory()
    model_path = models_dir / model_info["file"]
    temp_path = model_path.with_suffix('.tmp')

    # Check if already exists
    if model_path.exists() and not force:
        # Verify checksum if available
        stored_checksum = model_info.get("checksum")
        if stored_checksum:
            actual_checksum = compute_checksum(model_path)
            if actual_checksum == stored_checksum:
                console.print(f"[green]✓ Model already installed and verified[/green]")
                console.print(f"  File: {model_path.name}")
                console.print(f"  Size: {model_info['size_mb']} MB")
                return True

    console.print(f"\n[cyan]📥 Downloading {model_info['name']} ({model_info['size_mb']} MB)...[/cyan]")
    console.print(f"  From: {model_info['huggingface']}")

    # Try huggingface_hub import
    try:
        from huggingface_hub import hf_hub_download
    except ImportError:
        console.print("\n[red]❌ huggingface_hub not installed[/red]")
        console.print("  Install with: pip install huggingface_hub")
        console.print(f"  Or download manually from: https://huggingface.co/{model_info['huggingface'].split('/')[0]}")
        return False

    # Retry logic
    max_retries = 3
    base_delay = 2  # seconds

    for attempt in range(1, max_retries + 1):
        try:
            # Download with progress bar
            with Progress(
                SpinnerColumn(),
                TextColumn("[progress.description]{task.description}"),
                BarColumn(bar_width=40),
                DownloadColumn(),
                TransferSpeedColumn(),
                TimeRemainingColumn(),
                console=console,
                refresh_per_second=10
            ) as progress:
                task = progress.add_task(
                    f"[cyan]Downloading {model_info['name']}[/cyan]",
                    total=None
                )

                # Download to temp file
                downloaded_path = hf_hub_download(
                    repo_id=model_info['huggingface'].split('/')[0],
                    filename=model_info['huggingface'].split('/')[-1],
                    local_dir=str(models_dir),
                    force_download=force
                )

                # Update progress (huggingface_hub doesn't expose progress easily)
                progress.update(task, completed=model_info['size_mb'])

            # Check if file was downloaded
            if Path(downloaded_path).exists():
                # Verify size
                actual_size_mb = Path(downloaded_path).stat().st_size / (1024 * 1024)
                size_variance = abs(actual_size_mb - model_info['size_mb']) / model_info['size_mb']

                if size_variance > 0.2:  # Allow 20% variance
                    console.print(f"\n[yellow]⚠️  Size mismatch detected[/yellow]")
                    console.print(f"  Expected: {model_info['size_mb']} MB")
                    console.print(f"  Actual: {round(actual_size_mb, 2)} MB")
                    if attempt < max_retries:
                        console.print(f"  Retrying... ({attempt}/{max_retries})")
                        time.sleep(base_delay * (2 ** (attempt - 1)))
                        continue
                    else:
                        console.print("[red]❌ Max retries exceeded[/red]")
                        return False

                # Compute checksum
                console.print("\n[yellow]🔍 Computing checksum...[/yellow]")
                checksum = compute_checksum(Path(downloaded_path))

                if not checksum:
                    console.print("[red]❌ Failed to compute checksum[/red]")
                    return False

                # Update registry with checksum
                MODELS_REGISTRY[model_name]["checksum"] = checksum
                if save_models_registry(MODELS_REGISTRY):
                    console.print(f"[green]✓ Checksum stored: {checksum[:16]}...[/green]")

                console.print(f"\n[green]✓ Model downloaded successfully![/green]")
                console.print(f"  File: {Path(downloaded_path).name}")
                console.print(f"  Size: {round(actual_size_mb, 2)} MB")
                console.print(f"  Checksum: {checksum}")
                return True
            else:
                raise Exception("Downloaded file not found")

        except KeyboardInterrupt:
            console.print("\n[yellow]⚠️  Download interrupted by user[/yellow]")
            console.print("  Resume with: synapse models download embedding")
            return False

        except Exception as e:
            if attempt < max_retries:
                console.print(f"\n[yellow]⚠️  Download attempt {attempt} failed: {e}[/yellow]")
                console.print(f"  Retrying in {base_delay * (2 ** (attempt - 1))}s...")
                time.sleep(base_delay * (2 ** (attempt - 1)))
            else:
                console.print(f"\n[red]❌ Download failed after {max_retries} attempts: {e}[/red]")
                console.print("\n  Manual download:")
                console.print(f"  1. Visit: https://huggingface.co/{model_info['huggingface'].split('/')[0]}")
                console.print(f"  2. Download: {model_info['file']}")
                console.print(f"  3. Place in: {models_dir}")
                return False

    return False


def verify_models():
    """Verify installed model integrity with size and checksum checks."""
    console.print("\n[cyan]🔍 Verifying Models:[/cyan]")
    console.print("=" * 50)

    models_dir = get_models_directory()
    all_valid = True

    for model_type, model_info in MODELS_REGISTRY.items():
        model_path = models_dir / model_info["file"]

        if not model_path.exists():
            console.print(f"\n[red]✗ {model_type}: Not installed[/red]")
            all_valid = False
            continue

        # Check file size
        size_mb = model_path.stat().st_size / (1024 * 1024)
        expected_size = model_info["size_mb"]

        # Allow 10% variance
        size_valid = abs(size_mb - expected_size) < (expected_size * 0.1)

        # Check checksum if available
        stored_checksum = model_info.get("checksum")
        checksum_status = "N/A"
        checksum_valid = True

        if stored_checksum:
            actual_checksum = compute_checksum(model_path)
            checksum_valid = actual_checksum == stored_checksum
            checksum_status = f"{stored_checksum[:16]}..." if stored_checksum else "N/A"
            if checksum_valid:
                checksum_status = f"[green]✓ {checksum_status}[/green]"
            else:
                checksum_status = f"[red]✗ {checksum_status}[/red]"
        else:
            checksum_status = "[yellow]⚠️  No checksum stored[/yellow]"

        status = "[green]✓ Valid[/green]" if (size_valid and (not stored_checksum or checksum_valid)) else "[red]✗ Invalid[/red]"

        console.print(f"\n[bold]{model_type.upper()}:[/bold]")
        console.print(f"  Path: {model_path}")
        console.print(f"  Expected size: {expected_size} MB")
        console.print(f"  Actual size: {round(size_mb, 2)} MB")
        console.print(f"  Checksum: {checksum_status}")
        console.print(f"  Status: {status}")

        if not size_valid or (stored_checksum and not checksum_valid):
            all_valid = False

    console.print("\n" + "=" * 50)
    if all_valid:
        console.print("[green]✓ All models verified successfully[/green]")
    else:
        console.print("[yellow]⚠️  Some models need attention[/yellow]")
        console.print("  Re-download with: synapse models download <model-name> --force")


def remove_model(model_name: str):
    """
    Remove installed model.

    Args:
        model_name: Model type (e.g., "embedding") or model name (e.g., "bge-m3")
    """
    # Check model exists in registry (by type or name)
    model_result = find_model_by_name_or_type(model_name)
    if model_result is None:
        # Build list of available model names
        available_names = [info.get("name", model_type) for model_type, info in MODELS_REGISTRY.items()]
        console.print(f"[red]❌ Unknown model: {model_name}[/red]")
        console.print(f"   Available models: {', '.join(MODELS_REGISTRY.keys())}")
        console.print(f"   Available by name: {', '.join(available_names)}")
        return False

    model_type, model_info = model_result
    models_dir = get_models_directory()
    model_path = models_dir / model_info["file"]

    console.print(f"\n[cyan]🗑️  Removing {model_info['name']}...[/cyan]")

    if not model_path.exists():
        console.print("  [red]✗ Model not installed[/red]")
        return False

    try:
        model_path.unlink()
        console.print("  [green]✓ Model removed successfully[/green]")
        return True
    except Exception as e:
        console.print(f"  [red]❌ Failed to remove model: {e}[/red]")
        return False
