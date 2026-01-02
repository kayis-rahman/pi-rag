# Contributing to TimeBeam

Welcome to TimeBeam! We appreciate your interest in contributing.

## Getting Started

### For New Contributors
1. Read [Project Overview](../README.md) to understand TimeBeam
2. Review [Code Style & Standards](../codestyle/) before making changes
3. Follow [Getting Started Guide](../getting-started/quick-start.md) to set up environment
4. Check [AGENTS Configuration](../../AGENTS.md) for AI-assisted development patterns

### For Bug Fixes
1. Search [Fixes Summary](../project-management/fixes-summary.md) for similar issues
2. Follow [Error Fixing Workflow](../../AGENTS.md#error-fixing-workflow)
3. Write tests for bug fixes
4. Update documentation if behavior changes

### For Feature Development
1. Check [MVP Checklist](../features/mvp-checklist.md) for feature status
2. Follow appropriate [workflow](../codestyle/workflows/):
   - [Backend Feature](../codestyle/workflows/backend-feature.md)
   - [Frontend Feature](../codestyle/workflows/frontend-feature.md)
3. Test thoroughly before submitting
4. Update documentation with examples

## How to Contribute

### Reporting Issues
- Use **bd (beads)** for persistent issue tracking
- Run `bd prime` for workflow context
- Create issues with clear titles and descriptions
- Include reproduction steps for bugs
- Tag issues appropriately (bug, enhancement, documentation)

### Submitting Pull Requests

1. **Create feature branch**: `git checkout -b feature/your-feature-name`
2. **Make changes** following [Code Style & Standards](../codestyle/)
3. **Write tests** for all changes (80% coverage minimum)
4. **Update documentation** if adding or changing features
5. **Run quality gates**:
   ```bash
   # Backend
   cd back-end && mvn test && mvn spotbugs:check pmd:check

   # Frontend
   cd apple/TimeBeam && swiftlint --strict
   ```
6. **Commit changes**: `git commit -m "Description of your changes"`
7. **Push to origin**: `git push origin feature/your-feature-name`
8. **Create pull request** with clear description
9. **Follow [PR Template](../../.github/pull_request_template.md)** checklist

## Code Style Guidelines

TimeBeam has comprehensive coding standards that all contributors must follow:

### Language-Specific Standards
- **Java**: [Java Standards](../codestyle/java.md) - Imports, naming, exception handling
- **Swift**: [Swift Standards](../codestyle/swift.md) - No force unwrap, memory management

### General Standards
- **Architecture**: [Architecture Overview](../architecture/overview.md) - DDD layered design
- **Logging**: [Logging Standards](../codestyle/logging.md) - AppLogger (iOS) and SLF4J (Java)
- **Security**: [Security Standards](../codestyle/security.md) - Input validation, no hardcoded secrets
- **Testing**: [Testing Standards](../codestyle/testing-backend.md) for backend or [Frontend Testing](../codestyle/testing-frontend.md) for frontend

### Documentation Standards
When creating or updating documentation, follow [Documentation Style Guide](creating-documents.md) and [Folder Structure](folder-structure.md).

## Development Workflows

### Standard Workflows
All development should follow established workflows:

| Task Type | Workflow Document |
|------------|------------------|
| Backend Feature | [Backend Feature](../codestyle/workflows/backend-feature.md) |
| Frontend Feature | [Frontend Feature](../codestyle/workflows/frontend-feature.md) |
| Code Refactoring | [Code Refactoring](../codestyle/workflows/refactoring.md) |
| Security Update | [Security Update](../codestyle/workflows/security-update.md) |
| General Task | [General Task](../codestyle/workflows/task.md) |

### Workflow Phases
All workflows follow a 5-phase structure:
1. **Analysis/Planning**: Understand requirements, create plan
2. **Implementation**: Write code following standards
3. **Testing**: Verify functionality with tests
4. **Review**: Code quality, security, architecture compliance
5. **Deployment**: Safe rollout with monitoring

## Testing

### Coverage Requirements
- **80% minimum** for all production code
- **100%** for critical paths (authentication, data processing)

### Test Types
- **Unit Tests**: Test individual components in isolation
- **Integration Tests**: Test component interactions
- **E2E Tests**: Test complete user workflows
- **UI Tests**: Test user interface and interactions

### Running Tests
**Backend:**
```bash
cd back-end
mvn test
```

**Frontend (iOS/macOS):**
```bash
cd apple/TimeBeam
xcodebuild test -scheme "TimeBeam iOS"
```

## Documentation Contribution

### When to Write Documentation
- Adding new features or significant changes
- Making architectural decisions
- Implementing complex workflows
- Recording bug fixes and solutions

### Documentation Guidelines
Follow [Creating Documentation](creating-documents.md) and [Style Guide](style-guide.md):
- Use kebab-case filenames
- Include clear descriptions
- Add code examples
- Link to related docs
- Update index files

## Code of Conduct

### Be Respectful
- Use inclusive language
- Respect differing viewpoints
- Provide constructive feedback
- Focus on what is best for the project

### Communication
- Be clear and concise in discussions
- Ask questions when uncertain
- Explain reasoning for decisions
- Acknowledge and learn from feedback

## Project Management

### Issue Tracking
- Use **bd (beads)** for tracking all work
- Run `bd ready` to find available tasks
- Update issue status as work progresses
- Reference related issues for context

### Branch Management
- Use feature branches: `feature/your-feature-name`
- Use fix branches: `fix/your-bug-fix`
- Keep main branch stable
- Rebase before merging to maintain clean history

## Getting Help

### Questions
- **Setup issues**: Check [Getting Started](../getting-started/) guides
- **Architecture questions**: Review [Architecture Overview](../architecture/overview.md)
- **Code style questions**: Review [Code Style & Standards](../codestyle/)
- **Testing questions**: Check [Testing](../testing/) documentation

### Community Support
- Create issues for questions or problems
- Join discussions in existing issues and pull requests
- Check [Fixes Summary](../project-management/fixes-summary.md) for similar issues

## Recognition

Contributors who significantly improve TimeBeam through code, documentation, testing, or community support will be recognized in the project.

## Related Documentation

- [Project Overview](../README.md) - Main project information
- [Code Style & Standards](../codestyle/) - Complete coding guidelines
- [AGENTS Configuration](../../AGENTS.md) - Agent-specific workflows
- [Getting Started](../getting-started/) - Onboarding guides

---

**Thank you for contributing to TimeBeam!** 🚀
