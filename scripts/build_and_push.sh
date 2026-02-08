#!/bin/bash
#
# Build and Push Script for Synapse Docker Images
#
# Usage:
#   ./scripts/build_and_push.sh [version]
#
# Examples:
#   ./scripts/build_and_push.sh v1.0.0    # Build and push specific version
#   ./scripts/build_and_push.sh latest    # Build and push latest tag
#   ./scripts/build_and_push.sh           # Build and tag as latest

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
DOCKER_REGISTRY="${DOCKER_REGISTRY:-}"  # Optional registry prefix
IMAGE_NAME="synapse"

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

validate_environment() {
    print_info "Validating environment..."
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        exit 1
    fi
    
    # Check if Dockerfile exists
    if [[ ! -f "${PROJECT_ROOT}/Dockerfile" ]]; then
        print_error "Dockerfile not found at ${PROJECT_ROOT}/Dockerfile"
        exit 1
    fi
    
    print_success "Environment validation passed"
}

get_version() {
    local version="${1:-latest}"
    
    # If version is "latest" or empty, use "latest"
    if [[ -z "$version" || "$version" == "latest" ]]; then
        echo "latest"
    else
        # Remove 'v' prefix if present
        echo "${version#v}"
    fi
}

build_image() {
    local version="$1"
    local full_image_name
    
    if [[ -n "$DOCKER_REGISTRY" ]]; then
        full_image_name="${DOCKER_REGISTRY}/${IMAGE_NAME}:${version}"
    else
        full_image_name="${IMAGE_NAME}:${version}"
    fi
    
    print_info "Building Docker image: $full_image_name"
    
    cd "$PROJECT_ROOT"
    
    # Build the image
    docker build \
        -t "$full_image_name" \
        -f Dockerfile \
        --build-arg BUILDKIT_INLINE_CACHE=1 \
        .
    
    print_success "Image built: $full_image_name"
    
    # Also tag as latest if it's a versioned release
    if [[ "$version" != "latest" ]]; then
        local latest_name
        if [[ -n "$DOCKER_REGISTRY" ]]; then
            latest_name="${DOCKER_REGISTRY}/${IMAGE_NAME}:latest"
        else
            latest_name="${IMAGE_NAME}:latest"
        fi
        
        docker tag "$full_image_name" "$latest_name"
        print_success "Tagged as: $latest_name"
    fi
}

push_image() {
    local version="$1"
    local full_image_name
    
    if [[ -n "$DOCKER_REGISTRY" ]]; then
        full_image_name="${DOCKER_REGISTRY}/${IMAGE_NAME}:${version}"
    else
        full_image_name="${IMAGE_NAME}:${version}"
    fi
    
    print_info "Pushing Docker image: $full_image_name"
    
    docker push "$full_image_name"
    
    print_success "Image pushed: $full_image_name"
    
    # Also push latest if it's a versioned release
    if [[ "$version" != "latest" ]]; then
        local latest_name
        if [[ -n "$DOCKER_REGISTRY" ]]; then
            latest_name="${DOCKER_REGISTRY}/${IMAGE_NAME}:latest"
        else
            latest_name="${IMAGE_NAME}:latest"
        fi
        
        docker push "$latest_name"
        print_success "Pushed: $latest_name"
    fi
}

verify_image() {
    local version="$1"
    local full_image_name
    
    if [[ -n "$DOCKER_REGISTRY" ]]; then
        full_image_name="${DOCKER_REGISTRY}/${IMAGE_NAME}:${version}"
    else
        full_image_name="${IMAGE_NAME}:${version}"
    fi
    
    print_info "Verifying image: $full_image_name"
    
    if docker inspect "$full_image_name" &>/dev/null; then
        print_success "Image verified: $full_image_name"
        
        # Show image details
        local size
        size=$(docker images --format "{{.Size}}" "$full_image_name")
        print_info "Image size: $size"
    else
        print_error "Image not found: $full_image_name"
        exit 1
    fi
}

main() {
    local version
    version=$(get_version "${1:-}")
    local push="${2:-false}"
    
    print_info "Synapse Docker Build Script"
    print_info "==========================="
    echo
    print_info "Version: $version"
    print_info "Registry: ${DOCKER_REGISTRY:-<none>}"
    echo
    
    # Validate environment
    validate_environment
    
    # Build the image
    build_image "$version"
    
    # Verify the image
    verify_image "$version"
    
    # Push if requested or if registry is set
    if [[ "$push" == "true" || -n "$DOCKER_REGISTRY" ]]; then
        echo
        read -p "Push image to registry? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            push_image "$version"
        else
            print_info "Push skipped"
        fi
    fi
    
    echo
    print_success "Build completed successfully!"
    echo
    print_info "Available images:"
    docker images | grep "^${IMAGE_NAME}"
    echo
    print_info "To run the container:"
    if [[ -n "$DOCKER_REGISTRY" ]]; then
        print_info "  docker run -d -p 8002:8002 ${DOCKER_REGISTRY}/${IMAGE_NAME}:${version}"
    else
        print_info "  docker run -d -p 8002:8002 ${IMAGE_NAME}:${version}"
    fi
}

# Show help
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    echo "Usage: $0 [version] [--push]"
    echo
    echo "Arguments:"
    echo "  version   - Version tag (e.g., v1.0.0, latest) [default: latest]"
    echo "  --push    - Push to registry after build"
    echo
    echo "Environment Variables:"
    echo "  DOCKER_REGISTRY - Optional registry prefix (e.g., docker.io/username)"
    echo
    echo "Examples:"
    echo "  $0 v1.0.0              # Build synapse:v1.0.0"
    echo "  $0 latest              # Build synapse:latest"
    echo "  $0 v1.0.0 --push       # Build and push synapse:v1.0.0"
    echo "  DOCKER_REGISTRY=docker.io/myuser $0 v1.0.0  # Build with registry prefix"
    exit 0
fi

# Run main function
main "$@"
