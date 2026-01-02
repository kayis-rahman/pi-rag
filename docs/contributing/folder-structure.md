# Documentation Folder Structure

Complete guide to TimeBeam's documentation organization and structure.

## Overview

TimeBeam documentation is organized hierarchically under the `docs/` directory. All documentation follows consistent naming and formatting standards as defined in [Style Guide](style-guide.md).

## Root Structure

```
/Users/kayisrahman/Documents/workspace/ideas/time-beam/
├── AGENTS.md                          # Agent-specific configuration
├── README.md                           # Main project landing page
├── .beads/                            # Issue tracking (beads)
├── apple/                               # Frontend source code
│   └── TimeBeam/
└── docs/                                # All documentation
    ├── README.md                        # Documentation hub (THIS FILE)
    ├── codestyle/                       # Code style and standards
    ├── getting-started/                   # Developer onboarding
    ├── architecture/                      # System architecture
    ├── features/                          # Feature documentation
    ├── implementation-guides/            # How-to guides
    ├── event-based-sync/                # Timer sync system
    ├── ci-cd/                             # CI/CD documentation
    ├── testing/                            # Testing strategy
    ├── tools/                              # Tool-specific guides
    ├── project-management/                  # Project tracking
    └── contributing/                     # Contributor guidelines
```

## Directory Details

### Main Documentation Hub
**File**: `docs/README.md`

Central navigation point for all documentation. Includes:
- Project overview and quick start links
- Complete category listings with descriptions
- Quick reference tables
- Key metrics and status indicators

### Code Style & Standards
**Directory**: `docs/codestyle/`

Comprehensive coding standards and best practices:
- `README.md` - Main index
- `architecture.md` - DDD, SOLID, DRY/KISS/YAGNI
- `java.md` - Java-specific rules (imports, naming, error handling)
- `swift.md` - Swift-specific rules (force unwrap, memory, SwiftUI)
- `logging.md` - AppLogger (iOS) and SLF4J (Java) standards
- `security.md` - Security best practices
- `mcp-servers.md` - MCP server usage guide
- `testing-backend.md` - Backend testing (JUnit 5, coverage)
- `testing-frontend.md` - Frontend testing (XCTest, UI tests)
- `workflows/` - Development workflows:
  - `backend-feature.md` - Backend feature workflow (5 phases)
  - `frontend-feature.md` - Frontend feature workflow (5 phases)
  - `refactoring.md` - Code refactoring workflow
  - `security-update.md` - Security update workflow
  - `task.md` - Universal development task workflow

### Getting Started
**Directory**: `docs/getting-started/`

Onboarding guides for new developers:
- `README.md` - Overview and navigation
- `project-overview.md` - High-level introduction
- `setup-guide.md` - Detailed setup instructions
- `quick-start.md` - Fast path to local development

**Purpose**: Get developers productive quickly with minimal setup friction.

### Architecture
**Directory**: `docs/architecture/`

System architecture and design documentation:
- `overview.md` - Complete system architecture, technology stack
- `design-decisions.md` - Key design choices and tradeoffs

**Purpose**: Provide understanding of system design, technology choices, and architectural principles.

### Features
**Directory**: `docs/features/`

Feature documentation and tracking:
- `mvp-checklist.md` - MVP feature completion status

**Purpose**: Track feature progress and provide roadmap visibility.

### Implementation Guides
**Directory**: `docs/implementation-guides/`

Step-by-step implementation guides:

**Frontend (iOS/macOS/watchOS):**
- `ios/`
  - `client-implementation-checklist.md` - iOS client development checklist
  - `timer-sync-implementation.md` - Timer sync implementation details
  - `google-sign-in.md` - Google Sign-In integration guide

**Backend (Java/Spring Boot):**
- `backend/`
  - `api-reference.md` - Complete backend API documentation
  - `setup-guide.md` - Backend configuration and setup

**Purpose**: Provide detailed instructions for implementing specific features.

### Event-Based Sync
**Directory**: `docs/event-based-sync/`

Timer synchronization system documentation:
- `overview.md` - Event-based sync system overview
- `frontend-implementation.md` - Frontend sync implementation
- `implementation.md` - Complete implementation guide
- `status.md` - Implementation status tracking
- `summary.md` - Implementation summary and learnings

**Purpose**: Document the timer synchronization mechanism between client and server.

### CI/CD
**Directory**: `docs/ci-cd/`

Continuous integration and deployment documentation:
- `README.md` - CI/CD overview
- `comprehensive-plan.md` - Complete 5-stage implementation plan
- `stage-1/`
  - `README.md` - Stage 1 overview
  - `implementation-summary.md` - Stage 1 implementation details
  - `final-report.md` - Stage 1 completion report
  - `test-infrastructure.md` - Test infrastructure setup
  - `stage-1-final-report.md` - Stage 1 final report
  - `stage-1-implementation-summary.md` - Stage 1 implementation summary
  - `stage-1-test-infrastructure.md` - Stage 1 test infrastructure
  - `validate-stage1.sh` - Validation script

**Purpose**: Document automation, deployment pipelines, and quality gates.

### Testing
**Directory**: `docs/testing/`

Testing frameworks and strategies:
- `e2e-testing.md` - End-to-end testing guide
- `framework-overview.md` - Testing infrastructure overview

**Purpose**: Provide testing strategies, frameworks, and best practices.

### Tools
**Directory**: `docs/tools/`

Tool-specific setup and usage guides:
- `github-actions-setup.md` - GitHub Actions configuration

**Purpose**: Document tool setup, configuration, and usage for development workflows.

### Project Management
**Directory**: `docs/project-management/`

Project tracking and reporting:
- `fixes-summary.md` - Summary of bug fixes applied
- `test-results/`
  - `summary.md` - Test execution results summary

**Purpose**: Track issues, fixes, and test results for project visibility.

### Contributing
**Directory**: `docs/contributing/`

Guidelines for contributors:
- `creating-documents.md` - How to create documentation
- `style-guide.md` - Documentation formatting and style
- `folder-structure.md` - This file

**Purpose**: Ensure consistent, maintainable documentation.

## Naming Conventions

### File Naming
- Use **kebab-case** for all filenames: `project-overview.md`
- Use **descriptive names**: `timer-sync-implementation.md`
- **Avoid version numbers**: `guide.md` not `guide-v2.md`
- Use **category prefixes**: `ios/timer-sync.md`, `backend/api-reference.md`

### Directory Naming
- Use **lowercase** for all directory names: `getting-started/`, `implementation-guides/`
- Use **singular or plural consistently**: Prefer plural for content directories
- Use **descriptive names**: `codestyle/`, `event-based-sync/`

### Title Formatting
- Use `# Title Case` for main document titles
- Use `Sentence case` for section headings
- Be descriptive and concise

## File Placement Rules

### Where to Create Documentation

| Type of Doc | Location | Examples |
|--------------|-----------|----------|
| Project overview | `docs/` | README.md, getting-started/README.md |
| Architecture | `docs/architecture/` | overview.md, design-decisions.md |
| Feature docs | `docs/features/` | mvp-checklist.md |
| How-to guides | `docs/implementation-guides/` | ios/, backend/ subfolders |
| Code standards | `docs/codestyle/` | All standard files |
| Workflows | `docs/codestyle/workflows/` | backend-feature.md, etc. |
| CI/CD docs | `docs/ci-cd/` | README.md, comprehensive-plan.md |
| Testing | `docs/testing/` | e2e-testing.md, framework-overview.md |
| Tool setup | `docs/tools/` | github-actions-setup.md |
| Project tracking | `docs/project-management/` | fixes-summary.md |
| Feature-specific | Subfolder | docs/event-based-sync/ for sync system |
| Contributor guides | `docs/contributing/` | All guideline files |

### Where NOT to Create

- ❌ Don't create documentation at root level (except README.md and AGENTS.md)
- ❌ Don't create duplicate files across directories
- ❌ Don't use version numbers in filenames
- ❌ Don't mix concerns in single file (unless overview)

## Documentation Hierarchy

### Level 1: Entry Points
- `README.md` (root) - Main project landing
- `AGENTS.md` (root) - Agent-specific configuration
- `docs/README.md` - Documentation hub

### Level 2: Categories
- Each category folder has `README.md` for navigation
- Direct links to specific documentation files

### Level 3: Specific Documents
- Individual guides, references, and implementation details
- Should be single-purpose and focused

### Level 4: Related Links
- Links to other relevant documentation
- Cross-references where appropriate

## Maintenance

### Adding New Documentation

1. Choose appropriate category directory
2. Create file with descriptive kebab-case name
3. Follow [Style Guide](style-guide.md) for formatting
4. Update category README.md with new file
5. Update main `docs/README.md` if significant

### Updating Existing Documentation

1. Make changes to the file
2. Verify links still work
3. Update related documents if needed
4. Update index files (category and main)
5. Commit with descriptive message

### Removing Documentation

1. Check if file is referenced elsewhere
2. Update or remove references
3. Move to archive if historically useful
4. Delete if obsolete
5. Update index files

## Best Practices

### Organization
- Keep files focused on single topic
- Group related documentation together
- Use consistent naming across similar files
- Avoid deep nesting (max 3-4 levels deep)

### Navigation
- Provide clear paths to information
- Use README.md files for category overviews
- Link to related documentation
- Include quick reference tables where helpful

### Quality
- Write in clear, concise language
- Keep content up to date
- Remove outdated information
- Test code examples and commands

## Related Documentation

- [Style Guide](style-guide.md) - Formatting and writing standards
- [Creating Documentation](creating-documents.md) - How to write docs
- [AGENTS Configuration](../../AGENTS.md) - Agent-specific commands

---

**Organized documentation is easier to maintain and navigate!** 📖
