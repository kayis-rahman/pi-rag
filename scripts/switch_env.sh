#!/bin/bash
#
# Environment Switching Script for Synapse
#
# Usage:
#   ./scripts/switch_env.sh [dev|prod]
#   ./scripts/switch_env.sh              # Interactive mode
#
# Examples:
#   ./scripts/switch_env.sh dev          # Switch to development environment
#   ./scripts/switch_env.sh prod         # Switch to production environment

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
ENV_FILE="${PROJECT_ROOT}/.env"
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

get_current_env() {
    if [[ -f "$ENV_FILE" ]]; then
        # shellcheck source=/dev/null
        source "$ENV_FILE"
        echo "${SYNAPSE_ACTIVE_ENV:-none}"
    else
        echo "none"
    fi
}

save_env() {
    local env="$1"
    echo "SYNAPSE_ACTIVE_ENV=$env" > "$ENV_FILE"
}

show_status() {
    local current_env
    current_env=$(get_current_env)
    
    echo
    print_info "Current Environment: $current_env"
    echo
    print_info "Available Environments:"
    print_info "  dev  - Development (port 8003, synapse:latest)"
    print_info "  prod - Production (port 8002, synapse:v1.0.0)"
    echo
    print_info "Docker Services Status:"
    
    cd "$PROJECT_ROOT"
    if docker compose ps &>/dev/null; then
        docker compose ps
    else
        print_warning "No services running"
    fi
    echo
}

stop_all_services() {
    print_info "Stopping all services..."
    
    cd "$PROJECT_ROOT"
    docker compose down &>/dev/null || true
    
    print_success "All services stopped"
}

start_dev() {
    print_info "Starting development environment..."
    
    cd "$PROJECT_ROOT"
    docker compose up -d synapse-dev
    
    print_success "Development environment started"
    print_info "Port: 8003"
    print_info "Image: synapse:latest"
    print_info "Config: synapse_dev.json"
}

start_prod() {
    print_info "Starting production environment..."
    
    cd "$PROJECT_ROOT"
    docker compose up -d synapse-prod
    
    print_success "Production environment started"
    print_info "Port: 8002"
    print_info "Image: synapse:v1.0.0"
    print_info "Config: synapse_prod.json"
}

start_both() {
    print_info "Starting both environments..."
    
    cd "$PROJECT_ROOT"
    docker compose up -d
    
    print_success "Both environments started"
    print_info "Development:  port 8003 (synapse:latest)"
    print_info "Production: port 8002 (synapse:v1.0.0)"
}

switch_env() {
    local target_env="$1"
    local current_env
    current_env=$(get_current_env)
    
    if [[ "$target_env" == "$current_env" ]]; then
        print_warning "Already on environment: $target_env"
        return 0
    fi
    
    print_info "Switching from '$current_env' to '$target_env'..."
    
    # Stop current services
    stop_all_services
    
    # Start new environment
    case "$target_env" in
        dev)
            start_dev
            ;;
        prod)
            start_prod
            ;;
        both)
            start_both
            ;;
        *)
            print_error "Unknown environment: $target_env"
            return 1
            ;;
    esac
    
    # Save new environment
    save_env "$target_env"
    
    print_success "Environment switched to: $target_env"
}

interactive_mode() {
    echo
    print_info "Synapse Environment Switcher"
    print_info "============================"
    echo
    
    local current_env
    current_env=$(get_current_env)
    print_info "Current environment: $current_env"
    echo
    
    echo "Select environment:"
    echo "  1) Development (port 8003)"
    echo "  2) Production (port 8002)"
    echo "  3) Both environments"
    echo "  4) Show status"
    echo "  5) Stop all"
    echo "  q) Quit"
    echo
    
    read -p "Enter choice: " -r choice
    
    case "$choice" in
        1)
            switch_env "dev"
            ;;
        2)
            switch_env "prod"
            ;;
        3)
            switch_env "both"
            ;;
        4)
            show_status
            ;;
        5)
            stop_all_services
            ;;
        q|Q)
            print_info "Goodbye!"
            exit 0
            ;;
        *)
            print_error "Invalid choice"
            ;;
    esac
}

main() {
    local target_env="${1:-}"
    
    # Check if docker compose is available
    if ! command -v docker compose &> /dev/null; then
        print_error "Docker Compose is not installed"
        exit 1
    fi
    
    # Check if docker compose.yml exists
    if [[ ! -f "$DOCKER_COMPOSE_FILE" ]]; then
        print_error "docker compose.yml not found at $DOCKER_COMPOSE_FILE"
        exit 1
    fi
    
    # Handle command line argument or interactive mode
    if [[ -z "$target_env" ]]; then
        # Interactive mode
        interactive_mode
    else
        # Command line mode
        case "$target_env" in
            dev|prod|both)
                switch_env "$target_env"
                ;;
            status)
                show_status
                ;;
            stop)
                stop_all_services
                ;;
            --help|-h)
                echo "Usage: $0 [dev|prod|both|status|stop]"
                echo
                echo "Commands:"
                echo "  dev     - Switch to development environment (port 8003)"
                echo "  prod    - Switch to production environment (port 8002)"
                echo "  both    - Start both environments"
                echo "  status  - Show current status"
                echo "  stop    - Stop all services"
                echo "  --help  - Show this help message"
                echo
                echo "With no arguments, runs in interactive mode."
                ;;
            *)
                print_error "Unknown command: $target_env"
                print_info "Run '$0 --help' for usage information"
                exit 1
                ;;
        esac
    fi
}

# Run main function
main "$@"
