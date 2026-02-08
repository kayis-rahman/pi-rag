"""
Phase 1 & 3 Test Utilities (Shared)

Common test fixtures and utility functions for CLI tests.
Extended for Phase 3 (Data Operations: ingest, query, bulk).
"""

import subprocess
import sys
import time
import json
import httpx
from pathlib import Path
from typing import Dict, Tuple, List, Optional

# Test results storage
test_results: List[Dict[str, any]] = []

# Timeouts for different command types
TIMEOUTS = {
    "setup": 60,      # seconds
    "config": 2,       # seconds
    "models_list": 2,    # seconds
    "start": 10,       # seconds
    "stop": 5,         # seconds
    "status": 2,        # seconds
    "compose": 10,      # seconds (docker compose operations)
    # Phase 3 timeouts
    "ingest": 300,      # seconds (5 min for large directories)
    "query": 10,        # seconds (10 sec for query)
    "bulk": 600,       # seconds (10 min for bulk)
    "health_check": 5,   # seconds
}

# Environments to test
ENVIRONMENTS = {
    "docker": {
        "command_prefix": ["docker", "exec", "rag-mcp"],
        "data_dir": "/app/data",
        "expected": True
    },
    "native": {
        "command_prefix": [],
        "data_dir": "/opt/synapse/data",
        "expected": True
    },
    "user_home": {
        "command_prefix": [],
        "data_dir": str(Path.home() / ".synapse" / "data"),
        "expected": False  # May not exist initially
    }
}


def run_command(
    command: List[str],
    timeout: int,
    check_exit_code: bool = True
) -> Tuple[int, str, str, float]:
    """
    Run command and return (exit_code, stdout, stderr, duration).

    Args:
        command: Command to execute (list of strings)
        timeout: Timeout in seconds
        check_exit_code: If True, raise AssertionError on non-zero exit

    Returns:
        Tuple of (exit_code, stdout, stderr, duration_seconds)

    Raises:
        AssertionError: If check_exit_code=True and exit_code != 0
    """
    start_time = time.time()
    try:
        result = subprocess.run(
            command,
            timeout=timeout,
            capture_output=True,
            text=True,
            check=not check_exit_code
        )
        duration = time.time() - start_time
        return (result.returncode, result.stdout, result.stderr, duration)
    except subprocess.TimeoutExpired:
        duration = time.time() - start_time
        return (-1, "", f"Command timed out after {timeout}s", duration)
    except Exception as e:
        duration = time.time() - start_time
        return (-1, "", str(e), duration)


def assert_success(
    test_name: str,
    exit_code: int,
    stdout: str,
    stderr: str,
    duration: float,
    timeout: int
) -> None:
    """
    Assert command succeeded (exit code 0, within timeout).

    Args:
        test_name: Name of the test
        exit_code: Command exit code
        stdout: Command stdout
        stderr: Command stderr
        duration: Command duration in seconds
        timeout: Expected timeout threshold

    Raises:
        AssertionError: If exit code != 0 or duration > timeout
    """
    # Assert exit code
    if exit_code != 0:
        raise AssertionError(
            f"{test_name}: FAILED - Exit code {exit_code}\n"
            f"STDOUT:\n{stdout}\n\n"
            f"STDERR:\n{stderr}"
        )

    # Assert timeout
    if duration > timeout:
        raise AssertionError(
            f"{test_name}: FAILED - Performance degradation\n"
            f"Duration: {duration:.2f}s (timeout: {timeout}s)"
        )

    print(f"✅ {test_name}: PASSED (duration: {duration:.2f}s)")


def assert_output_contains(
    test_name: str,
    stdout: str,
    expected_text: str
) -> None:
    """
    Assert output contains expected text.

    Args:
        test_name: Name of the test
        stdout: Command stdout
        expected_text: Expected substring in output

    Raises:
        AssertionError: If expected_text not found in stdout
    """
    if expected_text not in stdout:
        raise AssertionError(
            f"{test_name}: FAILED - Output missing expected text\n"
            f"Expected: '{expected_text}'\n"
            f"Got:\n{stdout}"
        )

    print(f"  ✓ Output contains: '{expected_text}'")


def assert_directory_exists(
    test_name: str,
    directory: str
) -> None:
    """
    Assert directory exists.

    Args:
        test_name: Name of the test
        directory: Directory path to check

    Raises:
        AssertionError: If directory doesn't exist
    """
    if not Path(directory).exists():
        raise AssertionError(
            f"{test_name}: FAILED - Directory not found\n"
            f"Expected: '{directory}'"
        )

    print(f"  ✓ Directory exists: {directory}")


def assert_timeout(
    test_name: str,
    duration: float,
    timeout: int
) -> None:
    """
    Assert command completed within timeout.

    Args:
        test_name: Name of the test
        duration: Command duration in seconds
        timeout: Expected timeout threshold

    Raises:
        AssertionError: If duration > timeout
    """
    if duration > timeout:
        raise AssertionError(
            f"{test_name}: FAILED - Performance degradation\n"
            f"Duration: {duration:.2f}s (timeout: {timeout}s)"
        )

    print(f"  ✓ Timeout check: {duration:.2f}s <= {timeout}s")


def check_docker_container() -> bool:
    """
    Check if Docker container 'rag-mcp' is running.

    Returns:
        True if container is running, False otherwise
    """
    try:
        result = subprocess.run(
            ["docker", "inspect", "-f", "{{.State}}", "rag-mcp"],
            capture_output=True,
            text=True,
            timeout=5
        )
        return result.returncode == 0 and "running" in result.stdout.lower()
    except Exception:
        return False


def check_directory_exists(directory: str) -> bool:
    """
    Check if directory exists.

    Args:
        directory: Directory path to check

    Returns:
        True if directory exists, False otherwise
    """
    return Path(directory).exists()


def record_test_result(
    test_id: str,
    name: str,
    command: str,
    environment: str,
    exit_code: int,
    stdout: str,
    stderr: str,
    duration: float,
    timeout: int,
    passed: bool,
    assertions: List[Dict[str, any]] = None
) -> None:
    """
    Record test result for later summary.

    Args:
        test_id: Unique test identifier
        name: Test name
        command: Command that was executed
        environment: Test environment (docker, native, user_home)
        exit_code: Command exit code
        stdout: Command stdout
        stderr: Command stderr
        duration: Command duration in seconds
        timeout: Timeout threshold
        passed: Whether test passed
        assertions: List of assertions (optional)
    """
    global test_results

    from datetime import datetime

    test_result = {
        "test_id": test_id,
        "name": name,
        "command": " ".join(command) if isinstance(command, list) else command,
        "environment": environment,
        "exit_code": exit_code,
        "stdout": stdout,
        "stderr": stderr,
        "duration": duration,
        "timeout": timeout,
        "passed": passed,
        "timestamp": datetime.now().isoformat(),
        "assertions": assertions or []
    }

    test_results.append(test_result)


def print_test_summary() -> None:
    """
    Print summary of all test results.
    """
    global test_results

    print(f"\n{'=' * 60}")
    print(f"Phase 1 Test Summary")
    print(f"{'=' * 60}")
    print(f"\nTotal tests: {len(test_results)}")
    print(f"Passed: {sum(1 for r in test_results if r['passed'])}")
    print(f"Failed: {sum(1 for r in test_results if not r['passed'])}")
    if len(test_results) > 0:
        print(f"Success rate: {sum(1 for r in test_results if r['passed']) / len(test_results) * 100:.1f}%")
    else:
        print(f"Success rate: 0.0%")

    # Print individual results
    print(f"\nTest Results:")
    print(f"{'-' * 60}")
    for result in test_results:
        status = "✅ PASS" if result['passed'] else "❌ FAIL"
        print(f"{status}: {result['name']} ({result['duration']:.2f}s, env: {result['environment']})")

        # Show failures
        if not result['passed']:
            print(f"  Exit code: {result['exit_code']}")
            if result['stderr']:
                print(f"  Error: {result['stderr'][:200]}")

    print(f"{'-' * 60}\n")


def print_success_rate() -> int:
    """
    Calculate and print success rate.

    Returns:
        Exit code (0 if all passed, 1 if any failed)
    """
    global test_results

    if not test_results:
        print("⚠️  No tests run")
        return 0

    failed_count = sum(1 for r in test_results if not r['passed'])

    if failed_count > 0:
        print(f"\n❌ {failed_count} test(s) failed")
        print(f"Phase incomplete - Fix failures and re-run")
        return 1
    else:
        print(f"\n✅ All {len(test_results)} tests passed!")
        return 0


# ============================================================================
# PHASE 3 UTILITIES: Data Operations (Ingest, Query, Bulk)
# ============================================================================

def run_ingest_command(
    path: str,
    project_id: str = "synapse",
    chunk_size: int = 500,
    environment: str = "native",
    timeout: int = 300
) -> Tuple[int, str, str, float]:
    """
    Run ingest command and return results.

    Args:
        path: File or directory path to ingest
        project_id: Project ID for storage
        chunk_size: Chunk size for processing
        environment: Test environment (docker, native, user_home)
        timeout: Command timeout in seconds

    Returns:
        Tuple of (exit_code, stdout, stderr, duration_seconds)
    """
    cmd = []
    if environment == "docker":
        cmd.extend(["docker", "exec", "rag-mcp"])

    cmd.extend([
        "synapse", "ingest", str(path),
        "--project-id", project_id,
        "--chunk-size", str(chunk_size)
    ])

    return run_command(cmd, timeout)


def run_query_command(
    query: str,
    top_k: int = 3,
    output_format: str = "json",
    environment: str = "native",
    timeout: int = 10
) -> Tuple[int, str, str, float]:
    """
    Run query command and return results.

    Args:
        query: Query text
        top_k: Number of results to return
        output_format: Output format (json, text)
        environment: Test environment (docker, native, user_home)
        timeout: Command timeout in seconds

    Returns:
        Tuple of (exit_code, stdout, stderr, duration_seconds)
    """
    cmd = []
    if environment == "docker":
        cmd.extend(["docker", "exec", "rag-mcp"])

    cmd.extend([
        "synapse", "query", query,
        "--top-k", str(top_k),
        "--format", output_format
    ])

    return run_command(cmd, timeout)


def run_bulk_command(
    path: str,
    project_id: str = "synapse",
    chunk_size: int = 500,
    environment: str = "native",
    timeout: int = 600
) -> Tuple[int, str, str, float]:
    """
    Run bulk-ingest command and return results.

    Args:
        path: Directory path to ingest
        project_id: Project ID for storage
        chunk_size: Chunk size for processing
        environment: Test environment (docker, native, user_home)
        timeout: Command timeout in seconds

    Returns:
        Tuple of (exit_code, stdout, stderr, duration_seconds)
    """
    cmd = []
    if environment == "docker":
        cmd.extend(["docker", "exec", "rag-mcp"])

    cmd.extend([
        "synapse", "bulk-ingest", str(path),
        "--project-id", project_id,
        "--chunk-size", str(chunk_size)
    ])

    return run_command(cmd, timeout)


def verify_ingestion(
    stdout: str,
    stderr: str
) -> Dict[str, int]:
    """
    Verify ingestion output and return statistics.

    Args:
        stdout: Command stdout
        stderr: Command stderr

    Returns:
        Dictionary with files_processed, chunks_created, errors
    """
    stats = {
        "files_processed": 0,
        "chunks_created": 0,
        "errors": 0
    }

    # Look for file count
    if "file" in stdout.lower():
        # Try to extract number
        import re
        files_match = re.search(r'(\d+)\s*file', stdout, re.IGNORECASE)
        if files_match:
            stats["files_processed"] = int(files_match.group(1))

    # Look for chunk count
    if "chunk" in stdout.lower():
        import re
        chunks_match = re.search(r'(\d+)\s*chunk', stdout, re.IGNORECASE)
        if chunks_match:
            stats["chunks_created"] = int(chunks_match.group(1))

    # Look for errors
    if "error" in stderr.lower() or "Error" in stderr:
        import re
        error_count = len(re.findall(r'[Ee]rror', stderr))
        stats["errors"] = max(1, error_count)

    return stats


def verify_query_results(
    stdout: str,
    format: str = "json"
) -> Dict[str, any]:
    """
    Verify query output and return results.

    Args:
        stdout: Command stdout
        format: Output format (json, text)

    Returns:
        Dictionary with results_count, has_citations, format_valid
    """
    results = {
        "results_count": 0,
        "has_citations": False,
        "format_valid": False,
        "similarity_scores": []
    }

    # Extract JSON from stdout (handle debug logs)
    json_start = stdout.find('{')
    json_end = stdout.rfind('}') + 1
    if json_start == -1:
        return results

    json_str = stdout[json_start:json_end]

    if format == "json":
        try:
            data = json.loads(json_str)
            results["format_valid"] = True

            # Handle MCP JSON-RPC response format
            # Format: {"jsonrpc": "2.0", "id": 1, "result": {"results": [...], "total": N, "message": "..."}}
            if "result" in data:
                result_data = data["result"]
                # Check if there's an error
                if isinstance(result_data, dict) and "isError" in result_data and result_data["isError"]:
                    # Error response
                    results["format_valid"] = False
                    return results
                # Extract results from nested content
                if isinstance(result_data, dict) and "content" in result_data:
                    # Nested content
                    content = result_data["content"]
                    if isinstance(content, list) and len(content) > 0:
                        # Parse nested JSON in text field
                        for item in content:
                            if isinstance(item, dict) and "text" in item:
                                try:
                                    inner = json.loads(item["text"])
                                    if "results" in inner:
                                        inner_results = inner["results"]
                                        if isinstance(inner_results, list):
                                            results["results_count"] = len(inner_results)
                                            for r in inner_results:
                                                if "similarity" in r:
                                                    results["similarity_scores"].append(r["similarity"])
                                except:
                                    pass
                elif isinstance(result_data, list):
                    results["results_count"] = len(result_data)
                elif isinstance(result_data, dict) and "results" in result_data:
                    results["results_count"] = len(result_data["results"])

            # Check for citations
            if "citation" in json_str or "source:" in json_str:
                results["has_citations"] = True

        except json.JSONDecodeError:
            pass

    return results


def server_health_check(port: int = 8002) -> bool:
    """
    Check if MCP server is healthy.

    Args:
        port: MCP server port

    Returns:
        True if server is healthy, False otherwise
    """
    try:
        response = httpx.get(
            f"http://localhost:{port}/health",
            timeout=TIMEOUTS["health_check"]
        )
        return response.status_code == 200
    except Exception:
        return False


def wait_for_server(
    port: int = 8002,
    max_wait: int = 30,
    check_interval: int = 2
) -> bool:
    """
    Wait for server to become available.

    Args:
        port: MCP server port
        max_wait: Maximum wait time in seconds
        check_interval: Check interval in seconds

    Returns:
        True if server became available, False if timed out
    """
    start_time = time.time()
    while time.time() - start_time < max_wait:
        if server_health_check(port):
            return True
        time.sleep(check_interval)
    return False


def ensure_server_running(
    port: int = 8002,
    timeout: int = 30
) -> bool:
    """
    Ensure MCP server is running, start if needed.

    Args:
        port: MCP server port
        timeout: Timeout for server start

    Returns:
        True if server is running, False otherwise
    """
    if server_health_check(port):
        return True

    print(f"⚠️  Server not running, attempting to start...")
    result = run_command(
        ["synapse", "start", "--port", str(port)],
        timeout=timeout
    )

    if result[0] == 0:
        return wait_for_server(port, max_wait=timeout)
    return False


# Test data directories for Phase 3
TEST_DIRECTORIES = {
    "small": "docs/specs/005-cli-priority-testing",  # ~10 files
    "medium": "docs/specs",  # ~50 files
    "large": "synapse",  # ~100 files
    "code": "synapse/cli",  # Python files
    "docs": "docs",  # Markdown files
}

# Query test cases for Phase 3
QUERY_TEST_CASES = [
    {
        "name": "Simple query",
        "query": "What is synapse?",
        "expected_results": True,
        "top_k": 3
    },
    {
        "name": "Configuration query",
        "query": "What are the configuration settings?",
        "expected_results": True,
        "top_k": 3
    },
    {
        "name": "No results query",
        "query": "xyznonexistent123",
        "expected_results": False,
        "top_k": 3
    },
]

# Performance thresholds for Phase 3
PERFORMANCE_THRESHOLDS = {
    "ingest_single_file": 5.0,  # seconds
    "ingest_directory_10": 30.0,  # seconds
    "query_simple": 5.0,  # seconds
    "bulk_100_files": 300.0,  # seconds (5 min)
}

# Error messages for Phase 3
ERROR_MESSAGES = {
    "invalid_path": "does not exist",
    "permission_denied": "Permission",
    "mcp_unavailable": "server|MCP",
    "invalid_project": "project",
}
