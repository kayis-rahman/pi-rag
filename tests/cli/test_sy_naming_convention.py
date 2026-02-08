#!/usr/bin/env python3
"""
Comprehensive Test: Feature 007 - sy Naming Convention Validation

This test validates that all CLI commands work with the new 'sy' naming convention
and that MCP tools are correctly renamed to sy.* format.

Naming Convention:
- OLD: python3 -m synapse.cli.main <command>
- NEW: python3 -m synapse.cli.main <command> (sy prefix in MCP tools)

MCP Tools Renamed (Feature 016):
- OLD: rag.list_projects → NEW: sy.proj.list
- OLD: rag.list_sources → NEW: sy.src.list
- OLD: rag.get_context → NEW: sy.ctx.get
- OLD: rag.search → NEW: sy.mem.search
- OLD: rag.ingest_file → NEW: sy.mem.ingest
- OLD: rag.add_fact → NEW: sy.mem.fact.add
- OLD: rag.add_episode → NEW: sy.mem.ep.add
"""

import subprocess
import sys
import time
import json
from pathlib import Path
from typing import Dict, Tuple, List, Optional
from datetime import datetime


# ============================================================================
# Test Configuration
# ============================================================================

TIMEOUTS = {
    "default": 30,
    "start": 60,
    "stop": 30,
    "ingest": 300,
    "query": 30,
    "docker": 120
}

TEST_RESULTS = []


def record_test_result(test_id: str, test_name: str, status: str, duration: float = 0.0):
    """Record test result"""
    TEST_RESULTS.append({
        "test_id": test_id,
        "test_name": test_name,
        "status": status,
        "duration": duration,
        "timestamp": datetime.now().isoformat()
    })


def run_command(cmd: List[str], timeout: int = 30) -> Tuple[int, str, str, float]:
    """Run command and return (exit_code, stdout, stderr, duration)"""
    start = time.time()
    try:
        result = subprocess.run(
            cmd,
            timeout=timeout,
            capture_output=True,
            text=True
        )
        duration = time.time() - start
        return result.returncode, result.stdout, result.stderr, duration
    except subprocess.TimeoutExpired:
        duration = time.time() - start
        return -1, "", f"Timed out after {timeout}s", duration
    except Exception as e:
        duration = time.time() - start
        return -1, "", str(e), duration


def run_sy_command(args: str, timeout: int = 30) -> Tuple[int, str, str, float]:
    """Run sy command with new naming convention"""
    cmd = [sys.executable, "-m", "synapse.cli.main"] + args.split()
    return run_command(cmd, timeout)


# ============================================================================
# CLI Command Tests
# ============================================================================

def test_cli_help():
    """Test 1: sy --help"""
    test_id = "CLI-001"
    print(f"\n--- {test_id}: sy --help ---")
    exit_code, stdout, stderr, duration = run_sy_command("--help")
    success = exit_code == 0 and "Commands" in stdout
    record_test_result(test_id, "sy --help", "passed" if success else "failed", duration)
    return success, duration


def test_cli_start():
    """Test 2: sy start"""
    test_id = "CLI-002"
    print(f"\n--- {test_id}: sy start ---")
    exit_code, stdout, stderr, duration = run_sy_command("start", timeout=TIMEOUTS["start"])
    success = exit_code == 0 and "started" in stdout.lower()
    record_test_result(test_id, "sy start", "passed" if success else "failed", duration)
    return success, duration


def test_cli_status():
    """Test 3: sy status"""
    test_id = "CLI-003"
    print(f"\n--- {test_id}: sy status ---")
    exit_code, stdout, stderr, duration = run_sy_command("status")
    success = exit_code == 0 and "Status" in stdout
    record_test_result(test_id, "sy status", "passed" if success else "failed", duration)
    return success, duration


def test_cli_config():
    """Test 4: sy config"""
    test_id = "CLI-004"
    print(f"\n--- {test_id}: sy config ---")
    exit_code, stdout, stderr, duration = run_sy_command("config")
    success = exit_code == 0 and "Configuration" in stdout
    record_test_result(test_id, "sy config", "passed" if success else "failed", duration)
    return success, duration


def test_cli_models_list():
    """Test 5: sy models list"""
    test_id = "CLI-005"
    print(f"\n--- {test_id}: sy models list ---")
    exit_code, stdout, stderr, duration = run_sy_command("models list")
    success = exit_code == 0 and "Models" in stdout
    record_test_result(test_id, "sy models list", "passed" if success else "failed", duration)
    return success, duration


def test_cli_ingest():
    """Test 6: sy ingest"""
    test_id = "CLI-006"
    print(f"\n--- {test_id}: sy ingest ---")
    exit_code, stdout, stderr, duration = run_sy_command(
        "ingest /home/dietpi/synapse/README.md",
        timeout=TIMEOUTS["ingest"]
    )
    success = exit_code == 0 and "complete" in stdout.lower()
    record_test_result(test_id, "sy ingest", "passed" if success else "failed", duration)
    return success, duration


def test_cli_query():
    """Test 7: sy query"""
    test_id = "CLI-007"
    print(f"\n--- {test_id}: sy query ---")
    exit_code, stdout, stderr, duration = run_sy_command(
        'query "SYNAPSE"',
        timeout=TIMEOUTS["query"]
    )
    success = exit_code == 0 and ("result" in stdout.lower() or "ok" in stdout.lower())
    record_test_result(test_id, "sy query", "passed" if success else "failed", duration)
    return success, duration


def test_cli_setup_help():
    """Test 8: sy setup --help"""
    test_id = "CLI-008"
    print(f"\n--- {test_id}: sy setup --help ---")
    exit_code, stdout, stderr, duration = run_sy_command("setup --help")
    success = exit_code == 0 and "offline" in stdout.lower()
    record_test_result(test_id, "sy setup --help", "passed" if success else "failed", duration)
    return success, duration


def test_cli_onboard_help():
    """Test 9: sy onboard --help"""
    test_id = "CLI-009"
    print(f"\n--- {test_id}: sy onboard --help ---")
    exit_code, stdout, stderr, duration = run_sy_command("onboard --help")
    success = exit_code == 0 and "quick" in stdout.lower()
    record_test_result(test_id, "sy onboard --help", "passed" if success else "failed", duration)
    return success, duration


def test_cli_stop():
    """Test 10: sy stop"""
    test_id = "CLI-010"
    print(f"\n--- {test_id}: sy stop ---")
    exit_code, stdout, stderr, duration = run_sy_command("stop")
    success = exit_code == 0 and "stopped" in stdout.lower()
    record_test_result(test_id, "sy stop", "passed" if success else "failed", duration)
    return success, duration


# ============================================================================
# MCP Tools Tests (via Health Endpoint)
# ============================================================================

def test_mcp_tools_via_health():
    """Test 11: Verify MCP tools renamed to sy.* format"""
    test_id = "MCP-001"
    print(f"\n--- {test_id}: MCP Tools Renaming Verification ---")
    
    exit_code, stdout, stderr, duration = run_command(
        ["curl", "-s", "http://localhost:8002/health"],
        timeout=10
    )
    
    if exit_code != 0:
        record_test_result(test_id, "MCP tools verification", "failed", duration)
        return False, duration
    
    try:
        health = json.loads(stdout)
        tools = health.get("tools", [])
        
        # Expected renamed tools
        expected_tools = [
            "sy.proj.list",
            "sy.src.list", 
            "sy.ctx.get",
            "sy.mem.search",
            "sy.mem.ingest",
            "sy.mem.fact.add",
            "sy.mem.ep.add"
        ]
        
        # Check all renamed tools are present
        missing = [t for t in expected_tools if t not in tools]
        extra = [t for t in tools if t.startswith("sy.") and t not in expected_tools]
        
        success = len(missing) == 0 and len(extra) == 0
        
        if success:
            print(f"✅ All {len(expected_tools)} MCP tools renamed correctly")
            for tool in expected_tools:
                print(f"   - {tool}")
        else:
            if missing:
                print(f"❌ Missing tools: {missing}")
            if extra:
                print(f"❌ Extra tools: {extra}")
        
        record_test_result(test_id, "MCP tools verification", "passed" if success else "failed", duration)
        return success, duration
        
    except json.JSONDecodeError:
        print(f"❌ Failed to parse health response")
        record_test_result(test_id, "MCP tools verification", "failed", duration)
        return False, duration


def test_mcp_protocol():
    """Test 12: Verify MCP protocol version"""
    test_id = "MCP-002"
    print(f"\n--- {test_id}: MCP Protocol Verification ---")
    
    exit_code, stdout, stderr, duration = run_command(
        ["curl", "-s", "http://localhost:8002/health"],
        timeout=10
    )
    
    if exit_code != 0:
        record_test_result(test_id, "MCP protocol", "failed", duration)
        return False, duration
    
    try:
        health = json.loads(stdout)
        protocol = health.get("protocol", "")
        version = health.get("version", "")
        
        success = "MCP" in protocol and "2.0" in version
        
        if success:
            print(f"✅ Protocol: {protocol} v{version}")
        else:
            print(f"❌ Unexpected protocol: {protocol}")
        
        record_test_result(test_id, "MCP protocol", "passed" if success else "failed", duration)
        return success, duration
        
    except json.JSONDecodeError:
        record_test_result(test_id, "MCP protocol", "failed", duration)
        return False, duration


# ============================================================================
# Main Test Runner
# ============================================================================

def main():
    """Run all sy naming convention tests"""
    
    print("="*70)
    print("Feature 007 - sy Naming Convention Validation")
    print("="*70)
    print()
    print("Naming Convention: sy (MCP tools)")
    print("CLI: python3 -m synapse.cli.main <command>")
    print()
    
    # Start server for MCP tests
    print("Starting server for MCP tests...")
    run_sy_command("start", timeout=TIMEOUTS["start"])
    time.sleep(3)
    
    # CLI Tests
    cli_tests = [
        ("sy --help", test_cli_help),
        ("sy start", test_cli_start),
        ("sy status", test_cli_status),
        ("sy config", test_cli_config),
        ("sy models list", test_cli_models_list),
        ("sy ingest", test_cli_ingest),
        ("sy query", test_cli_query),
        ("sy setup --help", test_cli_setup_help),
        ("sy onboard --help", test_cli_onboard_help),
        ("sy stop", test_cli_stop),
    ]
    
    cli_passed = 0
    cli_total = len(cli_tests)
    cli_time = 0
    
    print("\n" + "="*70)
    print("CLI Command Tests")
    print("="*70)
    
    for name, test_func in cli_tests:
        try:
            success, duration = test_func()
            cli_time += duration
            if success:
                cli_passed += 1
                print(f"✅ PASSED ({duration:.2f}s)")
            else:
                print(f"❌ FAILED ({duration:.2f}s)")
        except Exception as e:
            cli_passed += 0
            print(f"❌ ERROR: {e}")
    
    # MCP Tests
    mcp_tests = [
        ("MCP Tools Renaming", test_mcp_tools_via_health),
        ("MCP Protocol", test_mcp_protocol),
    ]
    
    mcp_passed = 0
    mcp_total = len(mcp_tests)
    mcp_time = 0
    
    print("\n" + "="*70)
    print("MCP Tools Tests")
    print("="*70)
    
    for name, test_func in mcp_tests:
        try:
            success, duration = test_func()
            mcp_time += duration
            if success:
                mcp_passed += 1
                print(f"✅ PASSED ({duration:.2f}s)")
            else:
                print(f"❌ FAILED ({duration:.2f}s)")
        except Exception as e:
            mcp_passed += 0
            print(f"❌ ERROR: {e}")
    
    # Stop server
    print("\nStopping server...")
    run_sy_command("stop")
    
    # Summary
    total_passed = cli_passed + mcp_passed
    total_tests = cli_total + mcp_total
    
    print("\n" + "="*70)
    print("Test Summary - Feature 007 sy Naming Convention")
    print("="*70)
    print()
    print("CLI Command Tests:")
    print(f"  Passed: {cli_passed}/{cli_total}")
    print(f"  Success Rate: {cli_passed/cli_total*100:.0f}%")
    print(f"  Total Time: {cli_time:.2f}s")
    print()
    print("MCP Tools Tests:")
    print(f"  Passed: {mcp_passed}/{mcp_total}")
    print(f"  Success Rate: {mcp_passed/mcp_total*100:.0f}%")
    print(f"  Total Time: {mcp_time:.2f}s")
    print()
    print("="*70)
    print("OVERALL")
    print("="*70)
    print(f"Total Tests: {total_tests}")
    print(f"Passed: {total_passed}")
    print(f"Failed: {total_tests - total_passed}")
    print(f"Success Rate: {total_passed/total_tests*100:.0f}%")
    print(f"Total Time: {cli_time + mcp_time:.2f}s")
    
    # Save results
    results_file = Path(__file__).parent / "test_results_sy_naming.json"
    with open(results_file, "w") as f:
        json.dump({
            "timestamp": datetime.now().isoformat(),
            "cli_tests": {
                "total": cli_total,
                "passed": cli_passed,
                "time": cli_time
            },
            "mcp_tests": {
                "total": mcp_total,
                "passed": mcp_passed,
                "time": mcp_time
            },
            "overall": {
                "total": total_tests,
                "passed": total_passed,
                "success_rate": f"{total_passed/total_tests*100:.0f}%"
            },
            "details": TEST_RESULTS
        }, f, indent=2)
    
    print(f"\nResults saved to: {results_file}")
    
    return total_passed == total_tests


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
