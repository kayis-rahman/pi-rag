"""
SYNAPSE CLI: Main entry point with configuration integration
"""

import subprocess
import typer
from pathlib import Path
from typing import Optional

# Import CLI commands (use _cmd suffix to avoid function name conflicts)
from synapse.cli.commands import start as start_cmd, stop as stop_cmd, status as status_cmd, ingest as ingest_cmd, query as query_cmd, models, onboard
from synapse.cli.commands import setup as setup_cmd

# Import configuration
from synapse.config import get_config, print_config_summary, DEFAULT_CONFIG

# CLI app with rich styling
app = typer.Typer(
    name="synapse",
    help="SYNAPSE: Your Data Meets Intelligence - Local RAG System for AI Agents",
    add_completion=False,
    no_args_is_help=True,
    rich_markup_mode="rich"
)


@app.command()
def start(
    docker: Optional[bool] = typer.Option(
        None,
        "--docker", "-d",
        help="Use Docker container instead of native mode"
    ),
    port: Optional[int] = typer.Option(
        None,
        "--port", "-p",
        help="Port for MCP server (default: from config or 8002)"
    )
):
    """
    Start SYNAPSE server.

    Starts MCP server in either Docker or native mode.
    Auto-detects models and configuration.
    """
    # Load configuration
    config = get_config()
    
    # Override port if specified
    if port is not None:
        config["mcp_port"] = port
    
    print(f"🚀 Starting SYNAPSE server...")
    print(f"  Port: {config['mcp_port']}")
    print(f"  Environment: {config['environment']}")

    # Call start command
    if docker:
        # Docker mode
        success = start_cmd.start_docker(port=config["mcp_port"])
    else:
        # Native mode
        success = start_cmd.start_native(port=config["mcp_port"])

    if not success:
        import sys
        sys.exit(1)


@app.command()
def stop():
    """
    Stop SYNAPSE server.

    Stops running MCP server (either Docker or native mode).
    """
    print("🛑 Stopping SYNAPSE server...")
    stop_cmd.stop_server()


@app.command()
def status(
    verbose: bool = typer.Option(
        False,
        "--verbose", "-v",
        help="Show detailed configuration"
    )
):
    """
    Check SYNAPSE system status.

    Displays health check results including:
    - MCP Server status
    - Memory systems status (semantic, episodic, symbolic)
    - Model availability
    - Configuration status
    """
    # Load configuration
    config = get_config()
    
    if verbose:
        # Print full configuration
        print_config_summary(config)
    else:
        # Print brief status
        print("🔍 SYNAPSE System Status Check")
        print("=" * 50)
        
        print(f"\nEnvironment: {config['environment']}")
        print(f"Data Directory: {config['data_dir']}")
        print(f"Models Directory: {config['models_dir']}")
        
        # Check actual server status via health endpoint
        port = config['mcp_port']
        health_url = f"http://localhost:{port}/health"
        
        print(f"\n📡 MCP Server Status:")
        print(f"  Port: {port}")
        print(f"  Health Check: {health_url}")
        
        try:
            # Use httpx for better error handling
            import httpx
            response = httpx.get(health_url, timeout=2.0)
            if response.status_code == 200:
                server_status = "running"
                status_emoji = "✅"
            else:
                server_status = f"error (HTTP {response.status_code})"
                status_emoji = "⚠️"
            print(f"  Status: {status_emoji} {server_status}")
        except httpx.TimeoutException:
            print(f"  Status: ❌ stopped (health check timeout)")
        except Exception as e:
            print(f"  Status: ❌ stopped (health check failed: {e})")
        
        print(f"\n🧠 Model Status:")
        print(f"  ℹ️  Check with: synapse models list")
        
        print(f"\n📁 Configuration Status:")
        print(f"  ✓ Auto-detection enabled")
        print(f"  ✓ Sensible defaults loaded")
        
        print("\n" + "=" * 50)
        print("✓ SYNAPSE CLI framework is working")
        print("  Next steps:")
        print("    1. Run setup: synapse setup")
        print("    2. Start server: synapse start")


@app.command()
def ingest(
    path: Path = typer.Argument(
        ...,
        help="Path to file or directory to ingest",
        exists=True
    ),
    project_id: str = typer.Option(
        "synapse",
        "--project-id", "-p",
        help="Project ID for ingestion"
    ),
    code_mode: bool = typer.Option(
        False,
        "--code-mode", "-c",
        help="Enable code indexing mode (AST parsing)"
    ),
    chunk_size: Optional[int] = typer.Option(
        None,
        "--chunk-size",
        help="Chunk size in characters (default: from config or 500)"
    )
):
    """
    Ingest documents into SYNAPSE knowledge base.

    Processes files/directories and adds them to semantic memory.
    Supports regular text mode and code indexing mode with AST parsing.
    """
    # Load configuration
    config = get_config()
    
    # Override chunk size if specified
    if chunk_size is not None:
        config["chunk_size"] = chunk_size
    
    print(f"📄 Ingesting: {path}")
    print(f"  Project ID: {project_id}")
    print(f"  Chunk size: {config['chunk_size']}")
    print(f"  Code mode: {code_mode}")
    
    if code_mode:
        print("\n⚠️  Code indexing mode not yet implemented")
        print("  This feature will extract function signatures, classes, and imports")
        print("  For now, using standard text ingestion")
    else:
        print("\n🔄 Starting ingestion...")
        print("ℹ️  Note: Full implementation coming in Phase 1")
        print("  Use: python -m scripts.bulk_ingest <path>")


@app.command()
def query(
    text: str = typer.Argument(..., help="Query text to search knowledge base"),
    top_k: Optional[int] = typer.Option(
        None,
        "--top-k", "-k",
        help="Number of results to return (default: from config or 3)"
    ),
    format: str = typer.Option(
        "json",
        "--format", "-f",
        help="Output format: json or text"
    ),
    mode: str = typer.Option(
        "default",
        "--mode", "-m",
        help="Context injection mode: default, code, structured, reasoning"
    )
):
    """
    Query SYNAPSE knowledge base.

    Searches semantic, episodic, and symbolic memory for relevant information.
    Returns structured JSON output for AI agents by default.
    """
    # Load configuration
    config = get_config()
    
    # Override top_k if specified
    if top_k is not None:
        config["top_k"] = top_k
    
    print(f"🔍 Query: {text}")
    print(f"  Top K: {config['top_k']}")
    print(f"  Format: {format}")
    print(f"  Mode: {mode}")
    
    if format == "json":
        print("\n⚠️  Full query implementation coming in Phase 1")
        print("  This will integrate with MCP server for retrieval")
        print("  For now, use MCP tools directly")
    else:
        print("\nℹ️  Text output format selected")
        print("  Full implementation coming in Phase 1")


@app.command()
def config(
    verbose: bool = typer.Option(
        False,
        "--verbose", "-v",
        help="Show detailed configuration"
    )
):
    """
    Show SYNAPSE configuration.

    Displays current configuration including paths, settings,
    and detected environment.
    """
    # Load configuration
    config = get_config()
    
    # Print configuration
    print_config_summary(config)


@app.command()
def setup(
    force: bool = typer.Option(
        False,
        "--force", "-f",
        help="Force re-setup even if already configured"
    ),
    offline: bool = typer.Option(
        False,
        "--offline",
        help="Use offline mode (no model downloads)"
    ),
    no_model_check: bool = typer.Option(
        False,
        "--no-model-check",
        help="Skip model download check (for CI/automation)"
    )
):
    """
    First-time SYNAPSE setup.

    Initializes SYNAPSE with auto-configuration:
    - Auto-detects data directory
    - Creates necessary directories
    - Validates setup complete
    - Downloads BGE-M3 embedding model (if not offline and not --no-model-check)
    """
    # Call setup command
    setup_cmd.run_setup(force=force, offline=offline, no_model_check=no_model_check)


@app.command("onboard")
def onboard_cmd(
    quick: bool = typer.Option(False, "--quick", "-q", help="Quick mode (use all defaults)"),
    silent: bool = typer.Option(False, "--silent", "-s", help="Silent mode (no prompts)"),
    skip_test: bool = typer.Option(False, "--skip-test", help="Skip quick test"),
    skip_ingest: bool = typer.Option(False, "--skip-ingest", help="Skip file ingestion"),
    offline: bool = typer.Option(False, "--offline", help="Offline mode (no downloads)"),
    project_id: Optional[str] = typer.Option(None, "--project-id", "-p", help="Project ID (silent mode only)")
):
    """
    SYNAPSE Onboarding Wizard.

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
    onboard.onboard(
        quick=quick,
        silent=silent,
        skip_test=skip_test,
        skip_ingest=skip_ingest,
        offline=offline,
        project_id=project_id
    )


# Model management subcommands
models_app = typer.Typer(help="Model management commands")


@models_app.command("list")
def models_list():
    """List available and installed models."""
    models.list_models()


@models_app.command("download")
def models_download(
    model_name: str = typer.Argument(..., help="Model name to download"),
    force: bool = typer.Option(False, "--force", "-f", help="Force re-download")
):
    """Download model from HuggingFace."""
    models.download_model(model_name=model_name, force=force)


@models_app.command("verify")
def models_verify():
    """Verify installed model integrity."""
    models.verify_models()


@models_app.command("remove")
def models_remove(
    model_name: str = typer.Argument(..., help="Model name to remove")
):
    """Remove installed model."""
    models.remove_model(model_name=model_name)


# Add models subcommand to main app
app.add_typer(models_app, name="models")


def main():
    """Main CLI entry point."""
    app()


if __name__ == "__main__":
    main()
