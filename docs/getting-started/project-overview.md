# Getting Started

Welcome to TimeBeam! This guide will help you get up and running with the project.

## Project Overview

TimeBeam is a cross-platform Pomodoro timer application with:
- **Frontend**: SwiftUI-based apps for iOS, macOS, and watchOS
- **Backend**: Java Spring Boot REST API with PostgreSQL database
- **Architecture**: Domain-Driven Design (DDD) with clean separation of concerns

## Quick Links

- 📚 [Project README](../../README.md)
- 🔧 [Code Style & Standards](../codestyle/)
- 🤖 [AGENTS Configuration](../../AGENTS.md)
- 📖 [Features Checklist](../features/mvp-checklist.md)
- 🚀 [CI/CD Documentation](../ci-cd/)

## Prerequisites

### Development Environment
- **Java 17+** (for backend development)
- **Maven 3.8+** (backend build tool)
- **PostgreSQL 15+** (local development database)
- **Xcode 15+** (iOS/macOS/watchOS development)
- **Swift 5.9+** (iOS/macOS/watchOS development)

### Required Tools
- Git for version control
- Docker for containerized development
- Node.js (for frontend dependencies, if applicable)
- Maven for backend builds

## First Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd time-beam
   ```

2. **Install dependencies**
   - Backend: `cd back-end && mvn clean install`
   - Frontend: Open `apple/TimeBeam/TimeBeam.xcodeproj` in Xcode

3. **Configure environment**
   - Set up PostgreSQL database
   - Configure environment variables (see [Backend Setup](../implementation-guides/backend/setup-guide.md))
   - Set up Google Sign-In (see [Google Sign-In Guide](../implementation-guides/ios/google-sign-in.md))

4. **Run the application**
   - Backend: `cd back-end && mvn spring-boot:run`
   - iOS/macOS: Build and run from Xcode

## Architecture Overview

TimeBeam follows Domain-Driven Design (DDD) with four main layers:

1. **Domain Layer**: Business logic, entities, value objects
2. **Application Layer**: Use cases, orchestration, DTOs
3. **Infrastructure Layer**: Technical implementations (DB, APIs)
4. **Presentation Layer**: External interfaces (controllers, views)

For detailed architecture information, see [Architecture Overview](../architecture/overview.md)

## Development Workflow

TimeBeam uses structured development workflows. See [AGENTS Configuration](../../AGENTS.md) for:
- Build, lint, and test commands
- Code style guidelines
- Testing standards
- MCP server usage

## Next Steps

- Read the [Setup Guide](setup-guide.md) for detailed installation
- Check [Quick Start](quick-start.md) for a faster onboarding experience
- Review [Code Style & Standards](../codestyle/) before making changes
- Explore [Features Checklist](../features/mvp-checklist.md) to understand project scope

## Getting Help

- 📖 Review [Documentation Style Guide](../contributing/style-guide.md) for creating documentation
- 🐛 Check [Fixes Summary](../project-management/fixes-summary.md) for recent bug fixes
- 📊 Review [Event-Based Sync Documentation](../event-based-sync/) for timer synchronization details

---

**Welcome aboard!** Start with [Quick Start](quick-start.md) to begin contributing.
