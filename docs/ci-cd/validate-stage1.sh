#!/bin/bash

# Stage 1 Validation Script
# Validates that all Stage 1 deliverables are in place

set -e

echo "🔍 Validating Stage 1 Implementation..."
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track pass/fail
PASS=0
FAIL=0

check_file() {
    local file=$1
    local description=$2

    if [ -f "$file" ]; then
        echo -e "${GREEN}✅${NC} $description: $file"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}❌${NC} $description: $file"
        FAIL=$((FAIL + 1))
    fi
}

check_directory() {
    local dir=$1
    local description=$2

    if [ -d "$dir" ]; then
        echo -e "${GREEN}✅${NC} $description: $dir"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}❌${NC} $description: $dir"
        FAIL=$((FAIL + 1))
    fi
}

check_command() {
    local cmd=$1
    local description=$2

    if command -v $cmd &> /dev/null; then
        echo -e "${GREEN}✅${NC} $description: $cmd"
        PASS=$((PASS + 1))
    else
        echo -e "${YELLOW}⚠️${NC} $description: $cmd (not found)"
        FAIL=$((FAIL + 1))
    fi
}

# Check documentation
echo "📚 Documentation Files:"
check_file "docs/cicd-setup/COMPREHENSIVE_CI_CD_PLAN.md" "Comprehensive Plan"
check_file "docs/cicd-setup/STAGE1_TEST_INFRASTRUCTURE.md" "Stage 1 Guide"
check_file "docs/cicd-setup/STAGE1_IMPLEMENTATION_SUMMARY.md" "Stage 1 Summary"

echo ""
echo "🔧 Backend Configuration:"
check_file "back-end/pom.xml" "Maven POM"
check_file "back-end/src/test/resources/jacoco-agent-config.xml" "JaCoCo Agent Config"

echo ""
echo "🍎 iOS Configuration:"
check_file "apple/TimeBeam/.codecov.yml" "Codecov Config"

echo ""
echo "🤖 GitHub Workflows:"
check_file ".github/workflows/test-config.yml" "Test Config"
check_file ".github/workflows/test-unit.yml" "Unit Tests"
check_file ".github/workflows/test-integration.yml" "Integration Tests"
check_file ".github/workflows/test-report.yml" "Test Reports"
check_file ".github/workflows/ci.yml" "Main CI Pipeline"

echo ""
echo "🛠️ Required Tools:"
check_command "mvn" "Maven"
check_command "java" "Java"
check_command "git" "Git"

echo ""
echo "📊 Summary:"
echo -e "${GREEN}Passed:${NC} $PASS"
echo -e "${RED}Failed:${NC} $FAIL"

if [ $FAIL -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ All Stage 1 deliverables are in place!${NC}"
    echo ""
    echo "Next Steps:"
    echo "1. Test workflows locally with: act -j test-config"
    echo "2. Push to GitHub to trigger CI/CD pipeline"
    echo "3. Monitor execution times and coverage reports"
    echo "4. Review test reports and adjust thresholds if needed"
    exit 0
else
    echo ""
    echo -e "${RED}❌ Some deliverables are missing!${NC}"
    echo ""
    echo "Please review the failed items above and fix them before proceeding."
    exit 1
fi
