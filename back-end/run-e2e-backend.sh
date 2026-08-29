#!/bin/bash

# E2E Backend Runner Script
# This script sets up and runs the TimeBeam backend in E2E test mode
# with a dedicated test database and seeded data.

set -e

echo "🚀 Starting TimeBeam E2E Backend..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_COMPOSE_FILE="$PROJECT_ROOT/docker-compose.dev.yml"
E2E_DB_NAME="timebeam_e2e"
E2E_DB_USER="timebeam"
E2E_DB_PASSWORD="timebeam"
SPRING_PROFILE="e2e"
BACKEND_PORT=8081

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to wait for database to be ready
wait_for_db() {
    print_status "Waiting for PostgreSQL database to be ready..."

    local max_attempts=3
    local attempt=1

    # First wait for postgres system database
    while [ $attempt -le $max_attempts ]; do
        if PGPASSWORD=$E2E_DB_PASSWORD psql -h localhost -U $E2E_DB_USER -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
            print_success "PostgreSQL system database is ready!"
            break
        fi

        print_status "Attempt $attempt/$max_attempts: PostgreSQL not ready yet, waiting..."
        sleep 2
        ((attempt++))
    done

    if [ $attempt -gt $max_attempts ]; then
        print_error "PostgreSQL failed to start after $max_attempts attempts"
        return 1
    fi

    # Now create the E2E database
    print_status "Creating E2E database..."
    PGPASSWORD=$E2E_DB_PASSWORD psql -h localhost -U $E2E_DB_USER -d postgres -c "CREATE DATABASE $E2E_DB_NAME;" 2>/dev/null || true
    print_success "E2E database creation attempted"

    # Wait for E2E database to be accessible
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        if PGPASSWORD=$E2E_DB_PASSWORD psql -h localhost -U $E2E_DB_USER -d $E2E_DB_NAME -c "SELECT 1;" >/dev/null 2>&1; then
            print_success "E2E database is ready!"
            return 0
        fi

        print_status "Attempt $attempt/$max_attempts: E2E database not ready yet, waiting..."
        sleep 1
        ((attempt++))
    done

    print_error "E2E database failed to be ready after $max_attempts attempts"
    return 1
}

# Function to check if backend is ready
wait_for_backend() {
    print_status "Waiting for backend to be ready..."

    local max_attempts=3
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if curl -s -f http://localhost:$BACKEND_PORT/api/auth/health >/dev/null 2>&1; then
            print_success "Backend is ready!"
            return 0
        fi

        print_status "Attempt $attempt/$max_attempts: Backend not ready yet, waiting..."
        sleep 3
        ((attempt++))
    done

    print_error "Backend failed to start after $max_attempts attempts"
    return 1
}

# Check prerequisites
print_status "Checking prerequisites..."

if ! command_exists docker; then
    print_error "Docker is required but not installed. Please install Docker first."
    exit 1
fi

if ! command_exists mvn; then
    print_error "Maven is required but not installed. Please install Maven first."
    exit 1
fi

if ! command_exists psql; then
    print_warning "psql is not installed. Database connectivity checks will be skipped."
fi

print_success "Prerequisites check passed"

# Start PostgreSQL database
print_status "Starting PostgreSQL database with Docker Compose..."
cd "$PROJECT_ROOT"

if [ -f "$DOCKER_COMPOSE_FILE" ]; then
    # Try newer docker compose syntax first, fall back to older docker-compose
    if command_exists "docker" && docker compose version >/dev/null 2>&1; then
        DOCKER_COMPOSE_CMD="docker compose"
    elif command_exists "docker-compose"; then
        DOCKER_COMPOSE_CMD="docker-compose"
    else
        print_error "Neither 'docker compose' nor 'docker-compose' found"
        exit 1
    fi

    $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" up -d db

    if [ $? -eq 0 ]; then
        print_success "Database container started successfully"
    else
        print_error "Failed to start database container"
        exit 1
    fi
else
    print_error "Docker Compose file not found: $DOCKER_COMPOSE_FILE"
    exit 1
fi

# Wait for database to be ready
wait_for_db

# Clean and build the application
print_status "Building the application with Maven..."
cd "$PROJECT_ROOT"

mvn clean compile -q

if [ $? -eq 0 ]; then
    print_success "Application built successfully"
else
    print_error "Failed to build application"
    exit 1
fi

# Set environment variables for E2E testing
export SPRING_PROFILES_ACTIVE=$SPRING_PROFILE
export JWT_SECRET="e2e-test-jwt-secret-key-for-testing-purposes-only-not-for-production"
export APNS_ENABLED=false

# Start the backend in background
print_status "Starting backend server on port $BACKEND_PORT..."
mvn spring-boot:run -Dspring-boot.run.arguments="--spring.profiles.active=$SPRING_PROFILE" &
BACKEND_PID=$!

# Wait for backend to be ready
wait_for_backend

print_success "🎉 E2E Backend is now running!"
print_status "Backend URL: http://localhost:$BACKEND_PORT"
print_status "Health check: http://localhost:$BACKEND_PORT/api/auth/health"
print_status "Test user email: test@example.com"
print_status "Test user 2 email: test2@example.com"
print_status "Backend PID: $BACKEND_PID"

# Function to cleanup on script exit
cleanup() {
    print_status "Cleaning up..."
    if [ ! -z "$BACKEND_PID" ] && kill -0 $BACKEND_PID 2>/dev/null; then
        print_status "Stopping backend server (PID: $BACKEND_PID)..."
        kill $BACKEND_PID
        wait $BACKEND_PID 2>/dev/null || true
        print_success "Backend server stopped"
    fi

    print_status "Stopping database container..."
    $DOCKER_COMPOSE_CMD -f "$DOCKER_COMPOSE_FILE" down db
    print_success "Database container stopped"

    print_success "Cleanup completed"
}

# Set trap to cleanup on script exit
trap cleanup EXIT

# Keep the script running
print_status "Backend is running. Press Ctrl+C to stop..."
wait $BACKEND_PID
