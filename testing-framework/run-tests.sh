#!/bin/bash

# TimeBeam Testing Framework Runner
# Comprehensive testing script for multi-device synchronization

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FRAMEWORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$FRAMEWORK_DIR")"
RESULTS_DIR="$PROJECT_ROOT/test-results"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TEST_RUN_DIR="$RESULTS_DIR/run_$TIMESTAMP"

# Test categories
CATEGORIES=("multi-device-integration" "conflict-resolution" "concurrency-stress" "performance-benchmarks" "end-to-end-journeys")

# Default settings
VERBOSE=false
PERFORMANCE=false
CATEGORY="all"
REPORTS=false
CI_MODE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            CATEGORY="all"
            shift
            ;;
        --category)
            CATEGORY="$2"
            shift 2
            ;;
        --performance)
            PERFORMANCE=true
            shift
            ;;
        --monitor)
            PERFORMANCE=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --reports)
            REPORTS=true
            shift
            ;;
        --ci)
            CI_MODE=true
            shift
            ;;
        --help)
            echo "TimeBeam Testing Framework"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --all                    Run all test categories (default)"
            echo "  --category <name>        Run specific category"
            echo "  --performance            Enable performance monitoring"
            echo "  --monitor               Enable performance monitoring"
            echo "  --verbose               Enable verbose logging"
            echo "  --reports               Generate detailed reports"
            echo "  --ci                    Run in CI mode"
            echo "  --help                  Show this help message"
            echo ""
            echo "Available Categories:"
            for cat in "${CATEGORIES[@]}"; do
                echo "  - $cat"
            done
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Setup test environment
setup_test_environment() {
    echo -e "${BLUE}🚀 Setting up TimeBeam Testing Framework${NC}"
    
    # Create results directory
    mkdir -p "$TEST_RUN_DIR"
    mkdir -p "$TEST_RUN_DIR/logs"
    mkdir -p "$TEST_RUN_DIR/reports"
    mkdir -p "$TEST_RUN_DIR/metrics"
    
    # Set environment variables
    export TEST_VERBOSE="$VERBOSE"
    export TEST_PERFORMANCE="$PERFORMANCE"
    export TEST_RUN_ID="timebeam_$TIMESTAMP"
    export BUILD_NUMBER="${BUILD_NUMBER:-local}"
    export GIT_COMMIT="${GIT_COMMIT:-$(git rev-parse HEAD 2>/dev/null || echo 'unknown')}"
    export TEST_REPORTS="$REPORTS"
    
    # Test configuration file
    cat > "$TEST_RUN_DIR/test-config.env" << EOF
TEST_RUN_ID=$TEST_RUN_ID
TEST_VERBOSE=$TEST_VERBOSE
TEST_PERFORMANCE=$TEST_PERFORMANCE
BUILD_NUMBER=$BUILD_NUMBER
GIT_COMMIT=$GIT_COMMIT
TEST_REPORTS=$TEST_REPORTS
TEST_RESULTS_DIR=$TEST_RUN_DIR
EOF
    
    echo -e "${GREEN}✅ Test environment setup complete${NC}"
    echo "   Results directory: $TEST_RUN_DIR"
    echo "   Test Run ID: $TEST_RUN_ID"
}

# Check prerequisites
check_prerequisites() {
    echo -e "${BLUE}🔍 Checking prerequisites${NC}"
    
    # Check if we're in the right directory
    if [[ ! -d "$FRAMEWORK_DIR/shared" ]]; then
        echo -e "${RED}❌ Error: Not in TimeBeam project directory${NC}"
        exit 1
    fi
    
    # Check for required tools
    if ! command -v swift &> /dev/null; then
        echo -e "${YELLOW}⚠️  Warning: Swift not found (iOS/macOS tests may fail)${NC}"
    fi
    
    if ! command -v java &> /dev/null; then
        echo -e "${YELLOW}⚠️  Warning: Java not found (backend tests may fail)${NC}"
    fi
    
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}⚠️  Warning: Docker not found (container tests may fail)${NC}"
    fi
    
    echo -e "${GREEN}✅ Prerequisites check complete${NC}"
}

# Run backend tests
run_backend_tests() {
    echo -e "${BLUE}🔧 Running Backend Tests${NC}"
    
    cd "$PROJECT_ROOT/back-end"
    
    # Check if Maven wrapper exists
    if [[ -f "./mvnw" ]]; then
        MAVEN_CMD="./mvnw"
    elif command -v mvn &> /dev/null; then
        MAVEN_CMD="mvn"
    else
        echo -e "${YELLOW}⚠️  Maven not found, skipping backend tests${NC}"
        return 0
    fi
    
    # Set test profile
    export SPRING_PROFILES_ACTIVE=test
    
    # Run backend tests
    if $VERBOSE; then
        $MAVEN_CMD test -Dspring.profiles.active=test | tee "$TEST_RUN_DIR/logs/backend-tests.log"
    else
        $MAVEN_CMD test -Dspring.profiles.active=test > "$TEST_RUN_DIR/logs/backend-tests.log" 2>&1
    fi
    
    # Copy test results
    cp -r target/surefire-reports/ "$TEST_RUN_DIR/reports/" 2>/dev/null || true
    
    echo -e "${GREEN}✅ Backend tests completed${NC}"
}

# Run iOS/macOS/watchOS tests
run_platform_tests() {
    echo -e "${BLUE}📱 Running Platform Tests${NC}"
    
    cd "$PROJECT_ROOT/apple/TimeBeam"
    
    # Check if Xcode project exists
    if [[ ! -f "TimeBeam.xcodeproj/project.pbxproj" ]]; then
        echo -e "${YELLOW}⚠️  Xcode project not found, skipping platform tests${NC}"
        return 0
    fi
    
    # Build test scheme
    if ! xcodebuild -list TimeBeam.xcodeproj | grep -q "Testing"; then
        echo -e "${YELLOW}⚠️  No test scheme found, skipping platform tests${NC}"
        return 0
    fi
    
    # Run tests for each platform
    PLATFORMS=("iOS" "macOS" "watchOS")
    
    for platform in "${PLATFORMS[@]}"; do
        echo -e "${BLUE}🧪 Running $platform Tests${NC}"
        
        if $VERBOSE; then
            xcodebuild test \
                -project TimeBeam.xcodeproj \
                -scheme TimeBeam \
                -destination "platform=$platform Simulator,name=iPhone 14" \
                2>&1 | tee "$TEST_RUN_DIR/logs/$platform-tests.log"
        else
            xcodebuild test \
                -project TimeBeam.xcodeproj \
                -scheme TimeBeam \
                -destination "platform=$platform Simulator,name=iPhone 14" \
                > "$TEST_RUN_DIR/logs/$platform-tests.log" 2>&1
        fi
        
        # Copy test results
        cp -r *.xcresult "$TEST_RUN_DIR/reports/$platform.xcresult" 2>/dev/null || true
        
        echo -e "${GREEN}✅ $platform tests completed${NC}"
    done
}

# Run integration tests
run_integration_tests() {
    echo -e "${BLUE}🔄 Running Integration Tests${NC}"
    
    # Run Swift integration tests
    if [[ -f "$FRAMEWORK_DIR/multi-device-integration/CrossPlatformSyncTests.swift" ]]; then
        echo -e "${BLUE}📱 Running Cross-Platform Integration Tests${NC}"
        
        # Compile and run Swift tests
        cd "$FRAMEWORK_DIR"
        
        if $VERBOSE; then
            swift run --package-path . integration 2>&1 | tee "$TEST_RUN_DIR/logs/integration-tests.log"
        else
            swift run --package-path . integration > "$TEST_RUN_DIR/logs/integration-tests.log" 2>&1
        fi
        
        echo -e "${GREEN}✅ Integration tests completed${NC}"
    else
        echo -e "${YELLOW}⚠️  Integration tests not found${NC}"
    fi
}

# Run stress tests
run_stress_tests() {
    echo -e "${BLUE}🔥 Running Stress Tests${NC}"
    
    if [[ -f "$FRAMEWORK_DIR/concurrency-stress/SimultaneousActionsTests.swift" ]]; then
        echo -e "${BLUE}⚡ Running Concurrency Stress Tests${NC}"
        
        cd "$FRAMEWORK_DIR"
        
        if $VERBOSE; then
            swift run --package-path . stress 2>&1 | tee "$TEST_RUN_DIR/logs/stress-tests.log"
        else
            swift run --package-path . stress > "$TEST_RUN_DIR/logs/stress-tests.log" 2>&1
        fi
        
        echo -e "${GREEN}✅ Stress tests completed${NC}"
    else
        echo -e "${YELLOW}⚠️  Stress tests not found${NC}"
    fi
}

# Run performance benchmarks
run_performance_tests() {
    echo -e "${BLUE}📊 Running Performance Benchmarks${NC}"
    
    if [[ -f "$FRAMEWORK_DIR/performance-benchmarks/NetworkLatencyTests.swift" ]]; then
        echo -e "${BLUE}📈 Running Performance Tests${NC}"
        
        cd "$FRAMEWORK_DIR"
        
        if $VERBOSE; then
            swift run --package-path . performance 2>&1 | tee "$TEST_RUN_DIR/logs/performance-tests.log"
        else
            swift run --package-path . performance > "$TEST_RUN_DIR/logs/performance-tests.log" 2>&1
        fi
        
        echo -e "${GREEN}✅ Performance tests completed${NC}"
    else
        echo -e "${YELLOW}⚠️  Performance tests not found${NC}"
    fi
}

# Generate final report
generate_report() {
    echo -e "${BLUE}📋 Generating Final Report${NC}"
    
    # Collect all test results
    cat > "$TEST_RUN_DIR/test-summary.md" << EOF
# TimeBeam Test Report

## Test Run Information
- **Run ID**: $TEST_RUN_ID
- **Timestamp**: $TIMESTAMP
- **Category**: $CATEGORY
- **Build**: $BUILD_NUMBER
- **Git Commit**: $GIT_COMMIT
- **Performance Monitoring**: $PERFORMANCE

## Test Results

### Backend Tests
EOF
    
    # Parse backend test results
    if [[ -f "$TEST_RUN_DIR/logs/backend-tests.log" ]]; then
        BACKEND_TESTS=$(grep -c "Tests run:" "$TEST_RUN_DIR/logs/backend-tests.log" || echo "0")
        BACKEND_FAILURES=$(grep -c "FAILURE" "$TEST_RUN_DIR/logs/backend-tests.log" || echo "0")
        BACKEND_SUCCESS=$((BACKEND_TESTS - BACKEND_FAILURES))
        
        echo "- **Total Tests**: $BACKEND_TESTS" >> "$TEST_RUN_DIR/test-summary.md"
        echo "- **Passed**: $BACKEND_SUCCESS" >> "$TEST_RUN_DIR/test-summary.md"
        echo "- **Failed**: $BACKEND_FAILURES" >> "$TEST_RUN_DIR/test-summary.md"
    fi
    
    # Parse platform test results
    for platform in iOS macOS watchOS; do
        if [[ -f "$TEST_RUN_DIR/logs/$platform-tests.log" ]]; then
            PLATFORM_TESTS=$(grep -c "Test Case.*passed" "$TEST_RUN_DIR/logs/$platform-tests.log" || echo "0")
            PLATFORM_FAILURES=$(grep -c "Test Case.*failed" "$TEST_RUN_DIR/logs/$platform-tests.log" || echo "0")
            echo -e "\n### $platform Tests" >> "$TEST_RUN_DIR/test-summary.md"
            echo "- **Passed**: $PLATFORM_TESTS" >> "$TEST_RUN_DIR/test-summary.md"
            echo "- **Failed**: $PLATFORM_FAILURES" >> "$TEST_RUN_DIR/test-summary.md"
        fi
    done
    
    # Add performance summary if enabled
    if $PERFORMANCE && [[ -f "$TEST_RUN_DIR/logs/performance-tests.log" ]]; then
        echo -e "\n## Performance Summary" >> "$TEST_RUN_DIR/test-summary.md"
        echo "Performance metrics collected. See detailed logs." >> "$TEST_RUN_DIR/test-summary.md"
    fi
    
    # Generate HTML report if reports enabled
    if $REPORTS; then
        generate_html_report
    fi
    
    echo -e "${GREEN}✅ Report generated: $TEST_RUN_DIR/test-summary.md${NC}"
}

# Generate HTML report
generate_html_report() {
    cat > "$TEST_RUN_DIR/test-report.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>TimeBeam Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .header { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
        .section { margin: 20px 0; }
        .success { color: green; }
        .failure { color: red; }
        .warning { color: orange; }
    </style>
</head>
<body>
    <div class="header">
        <h1>TimeBeam Test Report</h1>
        <p><strong>Run ID:</strong> $TEST_RUN_ID</p>
        <p><strong>Timestamp:</strong> $TIMESTAMP</p>
        <p><strong>Category:</strong> $CATEGORY</p>
        <p><strong>Build:</strong> $BUILD_NUMBER</p>
    </div>
    
    <div class="section">
        <h2>Test Results</h2>
        <p>Detailed test results are available in the logs directory.</p>
    </div>
    
    <div class="section">
        <h2>Artifacts</h2>
        <ul>
            <li><a href="logs/">Test Logs</a></li>
            <li><a href="reports/">Test Reports</a></li>
            <li><a href="metrics/">Performance Metrics</a></li>
        </ul>
    </div>
</body>
</html>
EOF
}

# Cleanup function
cleanup() {
    echo -e "${BLUE}🧹 Cleaning up${NC}"
    
    # Remove temporary files
    find "$TEST_RUN_DIR" -name "*.tmp" -delete
    
    echo -e "${GREEN}✅ Cleanup complete${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}🎯 TimeBeam Testing Framework${NC}"
    echo "Starting comprehensive multi-device synchronization testing..."
    echo ""
    
    setup_test_environment
    check_prerequisites
    
    case $CATEGORY in
        "all")
            run_backend_tests
            run_platform_tests
            run_integration_tests
            run_stress_tests
            if $PERFORMANCE; then
                run_performance_tests
            fi
            ;;
        "multi-device-integration")
            run_integration_tests
            ;;
        "conflict-resolution")
            run_integration_tests
            ;;
        "concurrency-stress")
            run_stress_tests
            ;;
        "performance-benchmarks")
            run_performance_tests
            ;;
        "end-to-end-journeys")
            run_integration_tests
            ;;
        *)
            echo -e "${RED}❌ Unknown category: $CATEGORY${NC}"
            echo "Available categories: ${CATEGORIES[*]}"
            exit 1
            ;;
    esac
    
    generate_report
    cleanup
    
    echo ""
    echo -e "${GREEN}🎉 Testing completed successfully!${NC}"
    echo -e "${BLUE}📊 Results available at: $TEST_RUN_DIR${NC}"
    
    # Show summary
    TOTAL_TESTS=$(find "$TEST_RUN_DIR/logs" -name "*.log" -exec grep -l "Tests run:" {} \; | wc -l)
    TOTAL_FAILURES=$(find "$TEST_RUN_DIR/logs" -name "*.log" -exec grep -l "FAILURE" {} \; | wc -l)
    
    if [[ $TOTAL_FAILURES -eq 0 ]]; then
        echo -e "${GREEN}✅ All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}❌ Some tests failed. Check logs for details.${NC}"
        exit 1
    fi
}

# Trap cleanup on exit
trap cleanup EXIT

# Run main function
main "$@"