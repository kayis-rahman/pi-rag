# TimeBeam Documentation

Central documentation hub for TimeBeam Pomodoro timer application.

## 📖 Project Overview

**TimeBeam** is a cross-platform Pomodoro timer application built with:
- **Frontend**: SwiftUI-based apps for iOS, macOS, and watchOS
- **Backend**: Java Spring Boot REST API with PostgreSQL database
- **Architecture**: Domain-Driven Design (DDD) with clean separation of concerns

For detailed information, see [Project Overview](getting-started/project-overview.md).

## 🚀 Quick Start

Get up and running quickly:

- **[Quick Start Guide](getting-started/quick-start.md)** - Fastest path to a local development environment
- **[Setup Guide](getting-started/setup-guide.md)** - Detailed backend and frontend setup instructions
- **[Project Overview](getting-started/project-overview.md)** - High-level system understanding

## 📖 Documentation Categories

### Getting Started 🚀
Onboarding and setup guides for new developers:
- [Project Overview](getting-started/project-overview.md) - High-level project introduction
- [Setup Guide](getting-started/setup-guide.md) - Complete installation and configuration
- [Quick Start](getting-started/quick-start.md) - Fast path to local development

### Architecture 🏗️
System architecture and design decisions:
- [Architecture Overview](architecture/overview.md) - Complete system architecture
- [Design Decisions](architecture/design-decisions.md) - Key design choices and tradeoffs

### Features 🎯
Feature documentation and checklists:
- [MVP Checklist](features/mvp-checklist.md) - MVP feature completion status
- [Design Changes](architecture/design-decisions.md) - Proposed design updates

### Implementation Guides 📝
How-to guides for specific implementations:

**Frontend (iOS/macOS/watchOS):**
- [Client Implementation Checklist](implementation-guides/ios/client-implementation-checklist.md)
- [Timer Sync Implementation](implementation-guides/ios/timer-sync-implementation.md)
- [Google Sign-In Guide](implementation-guides/ios/google-sign-in.md)

**Backend (Java/Spring Boot):**
- [API Reference](implementation-guides/backend/api-reference.md) - Complete backend API documentation
- [Backend Setup Guide](implementation-guides/backend/setup-guide.md) - Backend configuration

### Code Style & Standards 🤖
Coding standards and best practices:
- [Main Index](../codestyle/README.md) - Complete code style documentation
- [Java Standards](../codestyle/java.md) - Java-specific rules
- [Swift Standards](../codestyle/swift.md) - Swift-specific rules
- [Testing - Backend](../codestyle/testing-backend.md) - Backend testing guidelines
- [Testing - Frontend](../codestyle/testing-frontend.md) - Frontend testing guidelines
- [Logging Standards](../codestyle/logging.md) - AppLogger and SLF4J usage
- [Security Standards](../codestyle/security.md) - Security best practices
- [MCP Servers Guide](../codestyle/mcp-servers.md) - MCP server usage

### Workflows & Processes ⚙️
Standardized development and operational workflows:
- [Backend Feature Workflow](../codestyle/workflows/backend-feature.md) - Backend feature development
- [Frontend Feature Workflow](../codestyle/workflows/frontend-feature.md) - Frontend feature development
- [Code Refactoring Workflow](../codestyle/workflows/refactoring.md) - Code refactoring process
- [Security Update Workflow](../codestyle/workflows/security-update.md) - Security fix process
- [General Task Workflow](../codestyle/workflows/task.md) - Universal development workflow

### CI/CD 🚀
Continuous integration and deployment:
- [CI/CD Overview](ci-cd/README.md) - Main CI/CD documentation
- [Comprehensive Plan](ci-cd/comprehensive-plan.md) - Complete CI/CD implementation plan
- [Stage 1](ci-cd/stage-1/README.md) - Stage 1 documentation and reports

### Testing 🧪
Testing frameworks and strategies:
- [E2E Testing](testing/e2e-testing.md) - End-to-end testing guide
- [Testing Framework](testing/framework-overview.md) - Testing infrastructure overview

### Tools & Setup 🔧
Tool-specific guides and configuration:
- [GitHub Actions Setup](tools/github-actions-setup.md) - CI/CD configuration

### Project Management 📊
Project tracking and reporting:
- [Fixes Summary](project-management/fixes-summary.md) - Summary of bug fixes and solutions
- [Test Results Summary](project-management/test-results/summary.md) - Test execution reports

### Event-Based Sync 🔄
Timer synchronization documentation:
- [Frontend Implementation](event-based-sync/frontend-implementation.md) - Frontend sync implementation
- [Implementation Details](event-based-sync/implementation.md) - Complete implementation guide
- [Status Tracking](event-based-sync/status.md) - Sync implementation status
- [Summary](event-based-sync/summary.md) - Implementation summary

### Contributing 🤝
Guidelines for contributors:
- [Creating Documentation](contributing/creating-documents.md) - How to create documentation
- [Style Guide](contributing/style-guide.md) - Documentation formatting standards
- [Folder Structure](contributing/folder-structure.md) - Documentation organization

## 🤖 Agent Configuration

AI assistant configuration for automated development:
- [AGENTS Configuration](../AGENTS.md) - Commands, workflows, and code style reference for AI agents

## Technology Stack

### Frontend
- **Language**: Swift 5.9+
- **Framework**: SwiftUI (declarative UI)
- **Platforms**: iOS 17+, macOS 14+, watchOS 10+
- **Architecture**: MVVM with Domain-Driven Design
- **Data**: UserDefaults, Keychain, Core Data
- **Networking**: URLSession, async/await
- **Testing**: XCTest framework

### Backend
- **Language**: Java 17
- **Framework**: Spring Boot 3.x
- **Database**: PostgreSQL 15+ (production), H2 (testing)
- **Build Tool**: Maven 3.8+
- **Architecture**: Domain-Driven Design (DDD) layered
- **Security**: JWT authentication, role-based authorization
- **API Documentation**: OpenAPI/Swagger
- **Testing**: JUnit 5 + Mockito

## Development Workflow

1. **Create Feature Branch**: `git checkout -b feature/your-feature-name`
2. **Follow Code Standards**: Review [Code Style & Standards](../codestyle/)
3. **Implement Feature**: Follow appropriate [workflow](../codestyle/workflows/)
4. **Test Changes**: Run backend and frontend tests
5. **Commit Changes**: `git commit -m "Description"`
6. **Create Pull Request**: Follow project guidelines
7. **Code Review**: Adhere to [MVP Checklist](features/mvp-checklist.md)

## Support & Resources

### Getting Help
- Review [Troubleshooting](getting-started/setup-guide.md#troubleshooting) sections
- Check [Fixes Summary](project-management/fixes-summary.md) for recent bug fixes
- Consult [Code Style & Standards](../codestyle/) for coding questions

### Documentation Help
- Follow [Documentation Style Guide](contributing/style-guide.md) when creating docs
- Use [Creating Documentation](contributing/creating-documents.md) for guidance
- Maintain [Folder Structure](contributing/folder-structure.md)

### Issue Tracking
- Use **bd (beads)** for persistent issue tracking
- Run `bd prime` for workflow context
- Commands: `bd ready`, `bd create`, `bd update`, `bd sync`

## Key Metrics

### MVP Completion
- **Overall Status**: 85% Complete
- **Core Features**: ✅ Timer, Session Logic, Analytics
- **Platform Support**: ✅ iOS, macOS, watchOS
- **Backend**: ✅ REST API, Authentication, Session Management
- **Testing**: ✅ Backend tests, Device testing

### Quality Standards
- **Code Coverage**: 80% minimum for all production code
- **100% Coverage**: For critical paths (authentication, data processing)
- **Code Quality**: Enforced via SwiftLint, SpotBugs, PMD
- **Documentation**: Comprehensive, organized, and up-to-date

## Quick Reference

| Category | Location | Purpose |
|----------|-----------|---------|
| Start Here | [getting-started/](getting-started/) | Onboarding & setup |
| Architecture | [architecture/](architecture/) | System design |
| Features | [features/](features/) | Feature docs |
| Implementation | [implementation-guides/](implementation-guides/) | How-to guides |
| Code Style | [../codestyle/](../codestyle/) | Coding standards |
| CI/CD | [ci-cd/](ci-cd/) | Automation |
| Testing | [testing/](testing/) | Testing strategy |
| Tools | [tools/](tools/) | Tool guides |
| Project Mgmt | [project-management/](project-management/) | Tracking |
| Event Sync | [event-based-sync/](event-based-sync/) | Timer sync |
| Contributing | [contributing/](contributing/) | Guidelines |

## Repository Links

- **Main Repository**: [View on GitHub](https://github.com/sparkage/timebeam)
- **Code of Conduct**: See repository
- **License**: See repository

---

**Welcome to TimeBeam!** Start with [Quick Start](getting-started/quick-start.md) or explore [Architecture Overview](architecture/overview.md) to understand the system.
