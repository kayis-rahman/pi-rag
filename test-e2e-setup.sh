#!/bin/bash

# Quick E2E Setup Test Script
# Tests the basic E2E infrastructure without waiting for full backend startup

set -e

echo "🧪 Testing E2E Setup..."

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to print colored output
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Test 1: Check if Docker is available and PostgreSQL container is running
print_info "Testing Docker and PostgreSQL..."
if docker ps | grep -q "timebeam_postgres"; then
    print_success "PostgreSQL container is running"
else
    print_error "PostgreSQL container not found. Run './back-end/run-e2e-backend.sh' first"
    exit 1
fi

# Test 2: Check if Maven project builds
print_info "Testing Maven build..."
cd back-end
if mvn compile -q -Dmaven.test.skip=true; then
    print_success "Maven project compiles successfully"
else
    print_error "Maven compilation failed"
    exit 1
fi

# Test 3: Check if test configuration files exist
print_info "Testing configuration files..."
if [ -f "src/test/resources/application-e2e.yml" ]; then
    print_success "E2E configuration file exists"
else
    print_error "E2E configuration file missing"
    exit 1
fi

# Test 4: Check if data seeder class exists
if [ -f "src/test/java/com/sparkage/timebeam/E2ETestDataSeeder.java" ]; then
    print_success "E2E data seeder class exists"
else
    print_error "E2E data seeder class missing"
    exit 1
fi

# Test 5: Check iOS test files
cd ../apple/TimeBeam
print_info "Testing iOS test files..."
if [ -f "TimeBeamUITests/TestConfiguration.swift" ]; then
    print_success "iOS test configuration exists"
else
    print_error "iOS test configuration missing"
    exit 1
fi

if [ -f "TimeBeamUITests/E2EAuthenticationTests.swift" ]; then
    print_success "E2E authentication tests exist"
else
    print_error "E2E authentication tests missing"
    exit 1
fi

if [ -f "TimeBeamUITests/E2ETimerWorkflowTests.swift" ]; then
    print_success "E2E timer workflow tests exist"
else
    print_error "E2E timer workflow tests missing"
    exit 1
fi

if [ -f "TimeBeamUITests/E2EMacOSTests.swift" ]; then
    print_success "E2E macOS tests exist"
else
    print_error "E2E macOS tests missing"
    exit 1
fi

if [ -f "TimeBeamUITests/E2ETaskManagementTests.swift" ]; then
    print_success "E2E task management tests exist"
else
    print_error "E2E task management tests missing"
    exit 1
fi

# Test 6: Check if Xcode project exists
print_info "Testing Xcode project..."
if [ -d "TimeBeam.xcodeproj" ]; then
    print_success "Xcode project exists"
else
    print_error "Xcode project not found"
    exit 1
fi

# Test 7: Check if README exists
if [ -f "../../E2E_TESTING_README.md" ]; then
    print_success "E2E testing documentation exists"
else
    print_error "E2E testing documentation missing"
    exit 1
fi

cd ../..

print_success "🎉 All E2E setup components are in place!"
print_info "To run full E2E tests:"
echo "  1. Terminal 1: cd back-end && ./run-e2e-backend.sh"
echo "  2. Terminal 2: cd apple/TimeBeam && xcodebuild test [options]"
echo "  3. See E2E_TESTING_README.md for detailed instructions"

exit 0
