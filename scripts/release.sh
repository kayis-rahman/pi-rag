#!/bin/bash
#
# Release Management Script for Synapse
#
# Usage:
#   ./scripts/release.sh [major|minor|patch]
#
# Examples:
#   ./scripts/release.sh patch   # v1.0.0 -> v1.0.1
#   ./scripts/release.sh minor   # v1.0.0 -> v1.1.0
#   ./scripts/release.sh major   # v1.0.0 -> v2.0.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DOCKER_COMPOSE_FILE="${PROJECT_ROOT}/docker-compose.yml"

# Functions
print_error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

get_current_version() {
    # Get the latest tag, default to v0.0.0 if no tags exist
    local latest_tag
    latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
    echo "$latest_tag"
}

bump_version() {
    local version="$1"
    local bump_type="$2"
    
    # Remove 'v' prefix
    version="${version#v}"
    
    # Split version into parts
    IFS='.' read -r major minor patch <<< "$version"
    
    case "$bump_type" in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
        *)
            print_error "Invalid bump type: $bump_type"
            exit 1
            ;;
    esac
    
    echo "v${major}.${minor}.${patch}"
}

validate_environment() {
    print_info "Validating environment..."
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not a git repository"
        exit 1
    fi
    
    # Check if working directory is clean
    if ! git diff-index --quiet HEAD --; then
        print_warning "Working directory has uncommitted changes"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        exit 1
    fi
    
    # Check if docker-compose is available
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed"
        exit 1
    fi
    
    print_success "Environment validation passed"
}

generate_release_notes() {
    local new_version="$1"
    local prev_version="$2"
    
    print_info "Generating release notes..."
    
    local release_notes_file="${PROJECT_ROOT}/release-notes.md"
    local date_str
    date_str=$(date +%Y-%m-%d)
    
    # Create release notes entry
    local release_entry="## ${new_version} - ${date_str}

### New Features
- Multi-environment Docker setup (dev: 8003, prod: 8002)
- Shared memory between Mac and Pi instances
- Environment-specific configurations
- Automated release management scripts

### Changes
- Renamed Docker images from rag-mcp to synapse
- Deprecated docker-compose.mcp.yml
- Added synapse-dev and synapse-prod services

### Migration Notes
- Backup data before migrating: \`cp -r /opt/synapse/data /opt/synapse/data.backup\`
- Use new docker-compose.yml for multi-environment setup
- Run \`./scripts/switch_env.sh\` to switch between environments

---

"
    
    # Check if release notes file exists
    if [[ -f "$release_notes_file" ]]; then
        # Prepend new entry to existing file
        local temp_file
        temp_file=$(mktemp)
        echo "$release_entry" | cat - "$release_notes_file" > "$temp_file"
        mv "$temp_file" "$release_notes_file"
    else
        # Create new file with header
        cat > "$release_notes_file" << EOF
# Release Notes

${release_entry}
EOF
    fi
    
    print_success "Release notes updated: $release_notes_file"
}

build_docker_image() {
    local version="$1"
    
    print_info "Building Docker image: synapse:${version}"
    
    cd "$PROJECT_ROOT"
    
    # Build the image
    docker build -t "synapse:${version}" -f Dockerfile .
    
    # Also tag as latest
    docker tag "synapse:${version}" "synapse:latest"
    
    print_success "Docker image built: synapse:${version}"
    print_info "Tagged as: synapse:latest"
}

main() {
    local bump_type="${1:-patch}"
    
    print_info "Synapse Release Script"
    print_info "======================"
    echo
    
    # Validate bump type
    if [[ ! "$bump_type" =~ ^(major|minor|patch)$ ]]; then
        print_error "Usage: $0 [major|minor|patch]"
        print_info "Example: $0 patch"
        exit 1
    fi
    
    # Validate environment
    validate_environment
    
    # Get current version
    local current_version
    current_version=$(get_current_version)
    print_info "Current version: $current_version"
    
    # Calculate new version
    local new_version
    new_version=$(bump_version "$current_version" "$bump_type")
    print_info "New version: $new_version"
    echo
    
    # Confirm with user
    read -p "Create release ${new_version}? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Release cancelled"
        exit 0
    fi
    
    # Create git tag
    print_info "Creating git tag: $new_version"
    git tag -a "$new_version" -m "Release $new_version"
    print_success "Git tag created"
    
    # Build Docker image
    build_docker_image "$new_version"
    
    # Generate release notes
    generate_release_notes "$new_version" "$current_version"
    
    echo
    print_success "Release $new_version completed successfully!"
    echo
    print_info "Next steps:"
    print_info "  1. Push the tag: git push origin $new_version"
    print_info "  2. Push the image: docker push synapse:$new_version"
    print_info "  3. Update docker-compose.yml to use synapse:$new_version"
    print_info "  4. Review and commit release-notes.md"
}

# Run main function
main "$@"
