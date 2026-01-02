# Getting Started

This section contains guides to help you get started with TimeBeam development.

## 📖 Documents

| Document | Description |
|----------|-------------|
| [Project Overview](project-overview.md) | High-level project overview, architecture, and quick links |
| [Setup Guide](setup-guide.md) | Detailed setup instructions for backend and frontend |
| [Quick Start](quick-start.md) | Fastest way to get TimeBeam running locally |

## Quick Start

For the fastest path to a running development environment, see [Quick Start](quick-start.md).

## Prerequisites

### Common Requirements
- Git for version control
- Basic understanding of:  - Java/Spring Boot (for backend)
  - Swift/SwiftUI (for frontend)
  - PostgreSQL (database)
  - Domain-Driven Design (DDD)
  - REST APIs

### Backend-Specific
- Java 17 or later
- Maven 3.8+
- PostgreSQL 15+ (or H2 for tests)
- Docker (optional but recommended)

### Frontend-Specific
- macOS 13+ (for iOS development)
- Xcode 15+
- Apple Developer Account (for device testing)
- iOS 17+ (minimum target)

## Development Environment Setup

### 1. Clone Repository
```bash
git clone <repository-url>
cd time-beam
```

### 2. Backend Setup
See detailed instructions in [Setup Guide - Backend](setup-guide.md#backend-setup-java-spring-boot).

Quick commands:
```bash
cd back-end
# Set environment variables
export SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/timebeam
export SPRING_DATASOURCE_USERNAME=postgres
export SPRING_DATASOURCE_PASSWORD=your_password
export JWT_SECRET=change-me-to-secure-random-string

# Build and run
mvn clean install
mvn spring-boot:run
```

Backend API: `http://localhost:8080`

### 3. Frontend Setup
See detailed instructions in [Setup Guide - Frontend](setup-guide.md#frontend-setup-iosmacoswatchos).

Quick commands:
```bash
cd apple/TimeBeam
# Open in Xcode
open TimeBeam.xcodeproj
# Press Cmd+R to build and run
```

## Verification

After setup, verify both applications are running:

### Backend Check
```bash
curl http://localhost:8080/actuator/health
```

Expected response: `{"status":"UP"}`

### Frontend Check
1. Timer starts and counts down correctly
2. Navigation works between tabs
3. Analytics charts display properly
4. Settings screen opens

### Integration Check
1. Frontend successfully calls backend APIs
2. Session data is synced correctly
3. Google Sign-In works end-to-end

## Next Steps

After getting started:

1. **Read Project Overview**: [Project Overview](project-overview.md) for understanding architecture
2. **Review Code Standards**: [Code Style & Standards](../codestyle/) for coding guidelines
3. **Explore Features**: [MVP Checklist](../features/mvp-checklist.md) for feature priorities
4. **Check Implementation Guides**: - [Backend API Reference](../implementation-guides/backend/api-reference.md)
  - [iOS Client Implementation Checklist](../implementation-guides/ios/client-implementation-checklist.md)
  - [Google Sign-In Guide](../implementation-guides/ios/google-sign-in.md)
  - [Timer Sync Implementation](../implementation-guides/ios/timer-sync-implementation.md)

## Common Issues

### Backend won't start
- Check PostgreSQL is running: `docker ps | grep postgres` or `pg_isready`
- Verify environment variables are set
- Check port 8080 is available: `lsof -i:8080`

### Frontend won't build
- Clean Xcode build folder: Product > Clean Build Folder
- Verify dependencies in Xcode project settings
- Update Xcode to latest version

### API calls fail
- Verify backend is running
- Check CORS configuration
- Review network settings
- Check JWT token generation

## Getting Help

If you encounter issues:

1. **Check logs**:   - Backend: `back-end/logs/timebeam.log`
   - Frontend: Console output in Xcode

2. **Review documentation**:   - [Troubleshooting in Setup Guide](setup-guide.md#troubleshooting)
   - [Error Fixing Workflow](../../AGENTS.md#error-fixing-workflow)

3. **Check existing issues**:   - [Fixes Summary](../project-management/fixes-summary.md)

## Development Workflow

1. **Create feature branch**: `git checkout -b feature/your-feature-name`
2. **Make changes** following code style standards
3. **Test locally**: Run backend and frontend tests
4. **Commit changes**: `git commit -m "Description"`
5. **Push and create PR**: Follow project guidelines

## Additional Resources

- 📚 [All Documentation](../)
- 🤖 [Code Style & Standards](../codestyle/)
- 🤖 [AGENTS Configuration](../../AGENTS.md)
- ✅ [Features Checklist](../features/mvp-checklist.md)
- 🚀 [CI/CD Documentation](../ci-cd/)

---

**Ready to code!** 🚀 Start with [Quick Start](quick-start.md) for the fastest onboarding experience.
