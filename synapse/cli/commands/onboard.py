"""
SYNAPSE CLI: Onboarding Command

Interactive first-time setup wizard that guides users through complete SYNAPSE initialization.
"""

import os
import shutil
import sys
from pathlib import Path
from typing import Optional

import typer
from rich.console import Console
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn
from rich.table import Table

# Add project root to path for imports
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

# Import SYNAPSE modules
from synapse.config import get_config, DEFAULT_CONFIG
from synapse.cli.commands.models import (
    download_model,
    verify_models,
    get_models_directory
)

console = Console()


def print_header(title: str):
    """Print formatted header."""
    console.print(Panel.fit(f"[bold cyan]{title}[/bold cyan]", border_style="cyan"))


def print_step(step_num: int, total_steps: int, title: str):
    """Print step header."""
    console.print(f"\n[bold]Step {step_num}/{total_steps}:[/bold] {title}")
    console.print("─" * 50)


def check_system_requirements() -> dict:
    """Check if system meets minimum requirements."""
    console.print("\n[yellow]Checking system requirements...[/yellow]")

    checks = {
        "python_version": True,
        "disk_space": True,
        "network": True,
        "details": {}
    }

    # Python version
    python_version = sys.version_info
    checks["details"]["python"] = f"{python_version.major}.{python_version.minor}.{python_version.micro}"
    if python_version < (3, 8):
        checks["python_version"] = False
        console.print("  [red]✗ Python 3.8+ required[/red]")
    else:
        console.print(f"  [green]✓ Python {checks['details']['python']}[/green]")

    # Disk space
    data_dir = Path.home() / ".synapse"
    try:
        disk_usage = shutil.disk_usage(data_dir)
        free_gb = disk_usage.free / (1024**3)
        checks["details"]["disk_space_gb"] = round(free_gb, 1)
        if free_gb < 2:
            checks["disk_space"] = False
            console.print(f"  [red]✗ Only {free_gb:.1f}GB free (need 2GB+)[/red]")
        else:
            console.print(f"  [green]✓ {free_gb:.1f}GB free space[/green]")
    except Exception as e:
        console.print(f"  [yellow]⚠ Could not check disk space: {e}[/yellow]")

    # Network check (simple)
    checks["details"]["network"] = "Available"
    try:
        import socket
        socket.create_connection(("huggingface.co", 80), timeout=5)
        console.print(f"  [green]✓ Network connectivity available[/green]")
    except Exception:
        checks["network"] = False
        checks["details"]["network"] = "Limited/Offline"
        console.print(f"  [yellow]⚠ Network connectivity limited (offline mode)[/yellow]")

    return checks


def setup_environment(config: dict, force: bool = False) -> bool:
    """Step 1: Environment Setup."""
    print_step(1, 3, "Environment Setup")

    # Environment
    env = config.get("environment", "native")
    console.print(f"[green]✓ Environment detected:[/green] {env}")

    # Directories
    console.print(f"\n[cyan]Directories:[/cyan]")
    dirs_to_create = [
        ("Data", config["data_dir"]),
        ("Models", config["models_dir"]),
        ("RAG Index", config["rag_index_dir"]),
        ("Docs", config["docs_dir"]),
        ("Logs", config["logs_dir"]),
    ]

    for name, path in dirs_to_create:
        path_obj = Path(path)
        if path_obj.exists():
            console.print(f"  [green]✓ {name}: {path}[/green]")
        else:
            try:
                path_obj.mkdir(parents=True, exist_ok=True)
                console.print(f"  [yellow]→ {name}: {path} (created)[/yellow]")
            except Exception as e:
                console.print(f"  [red]✗ Failed to create {name}: {e}[/red]")
                return False

    return True


def setup_model(
    config: dict,
    offline: bool = False,
    quick_mode: bool = False
) -> bool:
    """Step 2: Model Setup."""
    print_step(2, 3, "Model Setup")

    models_dir = get_models_directory()
    model_file = models_dir / "bge-m3-q8_0.gguf"

    # Check if model exists
    if model_file.exists():
        size_mb = model_file.stat().st_size / (1024 * 1024)
        console.print(f"\n[green]✓ BGE-M3 model found:[/green]")
        console.print(f"  File: {model_file.name}")
        console.print(f"  Size: {size_mb:.1f} MB")

        # Verify model
        if not quick_mode:
            console.print("\n[yellow]Verifying model integrity...[/yellow]")
            verify_models()

        return True

    # Model not found
    console.print("\n[red]⚠ BGE-M3 embedding model not found[/red]")
    console.print("  Model file: bge-m3-q8_0.gguf")
    console.print("  Size: ~730 MB")
    console.print("  Source: HuggingFace")

    if offline:
        console.print("\n[yellow]→ Offline mode: Skipping model download[/yellow]")
        console.print("  Download later with: synapse models download embedding")
        return False

    # Prompt to download
    if quick_mode or typer.confirm(
        "\n[cyan]Download BGE-M3 now?[/cyan]",
        default=True
    ):
        console.print("\n[cyan]Starting download...[/cyan]")
        success = download_model("embedding", force=False)

        if success:
            console.print("\n[green]✓ Model downloaded successfully[/green]")
            return True
        else:
            console.print("\n[red]✗ Model download failed[/red]")
            return False
    else:
        console.print("\n[yellow]→ Model download skipped[/yellow]")
        console.print("  Download later with: synapse models download embedding")
        return False


def setup_project(
    config: dict,
    project_id: Optional[str] = None,
    quick_mode: bool = False,
    silent: bool = False,
    skip_ingest: bool = False
) -> bool:
    """Step 3: Project Setup."""
    print_step(3, 3, "Project Setup")

    # Detect current directory
    current_dir = Path.cwd()
    console.print(f"\n[cyan]Project directory:[/cyan] {current_dir}")

    # Prompt for project ID
    if project_id is None:
        default_project_id = current_dir.name
        if quick_mode or silent:
            project_id = default_project_id
        else:
            project_id = typer.prompt(
                "\n[cyan]Project ID[/cyan]",
                default=default_project_id
            )

    console.print(f"[green]✓ Project ID: {project_id}[/green]")

    # Scan files
    console.print("\n[yellow]Scanning files...[/yellow]")

    # Import file scanner from bulk_ingest
    try:
        from scripts.bulk_ingest import FileScanner, GitignoreParser, FILE_TYPE_MAP
        from scripts.bulk_ingest import SUPPORTED_EXTENSIONS, SKIP_DIRS

        # Initialize scanner
        gitignore = GitignoreParser(None, [])
        scanner = FileScanner(str(current_dir), gitignore)

        # Scan files
        files = scanner.scan_files()

        # Count by type
        file_counts = {"code": 0, "doc": 0, "config": 0, "other": 0}
        for file_path, relative_path in files:
            file_type = scanner.get_file_type(file_path)
            if file_type in file_counts:
                file_counts[file_type] += 1
            else:
                file_counts["other"] += 1

        # Show summary
        console.print("\n[cyan]Files found:[/cyan]")
        for ftype, count in file_counts.items():
            if count > 0:
                console.print(f"  {ftype}: {count}")

    except Exception as e:
        console.print(f"\n[yellow]⚠ Could not scan files: {e}[/yellow]")
        console.print("  Will skip file ingestion")
        return True

    if skip_ingest:
        console.print("\n[yellow]→ File ingestion skipped[/yellow]")
        console.print("  Ingest later with: synapse ingest .")
        return True

    # Prompt to ingest
    if quick_mode or silent or typer.confirm(
        f"\n[cyan]Ingest {len(files)} files into semantic memory?[/cyan]",
        default=True
    ):
        console.print("\n[cyan]Starting ingestion...[/cyan]")

        # Import ingest functions
        try:
            from core.semantic_ingest import get_semantic_ingestor

            ingestor = get_semantic_ingestor()
            config_path = "./configs/rag_config.json"

            # Ingest with progress
            with Progress(
                SpinnerColumn(),
                TextColumn("[progress.description]{task.description}"),
                BarColumn(bar_width=40),
                console=console,
                refresh_per_second=10
            ) as progress:
                task = progress.add_task("[cyan]Ingesting files...", total=len(files))

                chunk_count = 0
                for file_path, relative_path in files:
                    try:
                        chunks = ingestor.ingest_file(
                            file_path=str(file_path),
                            metadata={
                                "filename": file_path.name,
                                "relative_path": relative_path,
                                "project_id": project_id
                            },
                            chunk_size=config.get("chunk_size", 500),
                            chunk_overlap=config.get("chunk_overlap", 50)
                        )
                        chunk_count += len(chunks)
                        progress.update(task, advance=1)
                    except Exception as e:
                        console.print(f"\n[yellow]⚠ Failed to ingest {file_path.name}: {e}[/yellow]")

                console.print(f"\n[green]✓ Ingested {len(files)} files ({chunk_count} chunks)[/green]")
                return True

        except Exception as e:
            console.print(f"\n[red]✗ Ingestion failed: {e}[/red]")
            console.print("  Run later with: synapse ingest .")
            return False
    else:
        console.print("\n[yellow]→ File ingestion skipped[/yellow]")
        console.print("  Ingest later with: synapse ingest .")
        return True


def run_quick_test(config: dict) -> bool:
    """Final Steps: Quick Test."""
    console.print("\n[bold]Final Steps: Quick Test[/bold]")
    console.print("─" * 50)

    console.print("\n[yellow]Running system test...[/yellow]")

    # Test 1: Model availability
    models_dir = get_models_directory()
    model_file = models_dir / "bge-m3-q8_0.gguf"

    if model_file.exists():
        console.print("  [green]✓ BGE-M3 model: Available[/green]")
    else:
        console.print("  [yellow]⚠ BGE-M3 model: Not downloaded[/yellow]")

    # Test 2: Vector store
    rag_index_dir = Path(config["rag_index_dir"])
    if rag_index_dir.exists():
        console.print("  [green]✓ Vector store: Ready[/green]")
    else:
        console.print("  [yellow]⚠ Vector store: Not initialized[/yellow]")

    # Test 3: Server not running check
    try:
        import requests
        response = requests.get(
            f"http://localhost:{config['mcp_port']}/health",
            timeout=2
        )
        console.print(f"  [green]✓ Server: Running on port {config['mcp_port']}[/green]")
    except:
        console.print(f"  [blue]ℹ Server: Not running (start with: synapse start)[/blue]")

    console.print("\n[bold green]✅ Onboarding Complete![/bold green]\n")

    return True


def print_summary(
    config: dict,
    project_id: str,
    model_downloaded: bool
):
    """Print summary and next steps."""
    console.print(Panel.fit(
        f"[bold green]Your SYNAPSE is ready to use![/bold green]",
        border_style="green"
    ))

    # Configuration table
    table = Table(title="Configuration", show_header=False)
    table.add_column("Setting", style="cyan")
    table.add_column("Value", style="white")

    table.add_row("Project", project_id)
    table.add_row("Data directory", config["data_dir"])
    table.add_row("Models directory", config["models_dir"])
    table.add_row("BGE-M3 model", "✓ Downloaded" if model_downloaded else "⚠ Not downloaded")

    console.print(table)
    console.print()

    # Next steps
    console.print("[bold cyan]Quick Start:[/bold cyan]")
    console.print("  1. Start server:  [cyan]synapse start[/cyan]")
    console.print("  2. Query code:   [cyan]synapse query \"How does auth work?\"[/cyan]")
    console.print("  3. Ingest more:  [cyan]synapse ingest ./docs[/cyan]")

    console.print("\n[bold cyan]Documentation:[/bold cyan]")
    console.print("  • Quick start:   [blue]https://docs.synapse.ai/quickstart[/blue]")
    console.print("  • Full docs:     [blue]https://docs.synapse.ai[/blue]")
    console.print("  • Troubleshoot: [blue]https://docs.synapse.ai/troubleshooting[/blue]")


def onboard(
    quick: bool = typer.Option(False, "--quick", "-q", help="Quick mode (use all defaults)"),
    silent: bool = typer.Option(False, "--silent", "-s", help="Silent mode (no prompts)"),
    skip_test: bool = typer.Option(False, "--skip-test", help="Skip quick test"),
    skip_ingest: bool = typer.Option(False, "--skip-ingest", help="Skip file ingestion"),
    offline: bool = typer.Option(False, "--offline", help="Offline mode (no downloads)"),
    project_id: Optional[str] = typer.Option(None, "--project-id", "-p", help="Project ID (silent mode only)")
):
    """
    SYNAPSE Onboarding Wizard

    Interactive first-time setup that guides you through:
    - Environment configuration
    - Model download (BGE-M3)
    - Project initialization
    - Quick start test

    Examples:
        synapse onboard                    # Interactive mode
        synapse onboard --quick            # Quick mode (all defaults)
        synapse onboard --silent            # Silent mode (no prompts)
        synapse onboard --skip-ingest       # Skip file ingestion
        synapse onboard --offline            # Offline mode (no downloads)
    """
    print_header("🚀 SYNAPSE Onboarding Wizard")

    # Load configuration
    config = get_config()

    # Silent mode validation
    if silent and project_id is None:
        console.print("[red]Error: --project-id required with --silent mode[/red]")
        raise typer.Exit(1)

    # System requirements check
    requirements = check_system_requirements()

    # Step 1: Environment Setup
    if not setup_environment(config):
        console.print("\n[red]✗ Environment setup failed[/red]")
        raise typer.Exit(1)

    # Step 2: Model Setup
    model_downloaded = setup_model(
        config,
        offline=offline,
        quick_mode=quick or silent
    )

    # Step 3: Project Setup
    if setup_project(
        config,
        project_id=project_id,
        quick_mode=quick or silent,
        silent=silent,
        skip_ingest=skip_ingest
    ):
        # Final Steps: Quick Test
        if not skip_test:
            run_quick_test(config)
        else:
            console.print("\n[bold green]✅ Onboarding Complete![/bold green]\n")

        # Print Summary
        print_summary(config, project_id or Path.cwd().name, model_downloaded)

    else:
        console.print("\n[red]✗ Project setup failed[/red]")
        raise typer.Exit(1)

    console.print()
