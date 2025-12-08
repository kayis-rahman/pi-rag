# Kilo Code Backend Feature Development

Standardized workflow for implementing new backend features using Kilo Code AI assistant.

## Trigger
- Backend feature requests
- API endpoint additions
- Database schema changes
- Business logic implementations

## Priority
High

## Estimated Duration
1-2 weeks

## Phases

### 1. Planning Phase
Analyze requirements and design the solution.

- [ ] Analyze requirements and acceptance criteria
- [ ] Design API contracts and data models
- [ ] Plan database schema changes
- [ ] Consider security implications

### 2. Implementation Phase
Implement the backend feature following DDD architecture.

- [ ] **Domain Layer**: Implement entities, value objects, and domain services
- [ ] **Application Layer**: Create application services and DTOs
- [ ] **Infrastructure Layer**: Implement repositories and external integrations
- [ ] **Presentation Layer**: Create REST controllers and DTOs
- [ ] Add comprehensive logging and monitoring

### 3. Testing Phase
Comprehensive testing of the implementation.

- [ ] Unit tests (minimum 80% coverage)
- [ ] Integration tests for API endpoints
- [ ] Security tests and validation
- [ ] Performance and load testing

### 4. Review Phase
Code review and validation.

- [ ] Code quality checks (SonarLint, security scanning)
- [ ] Security review and dependency scanning
- [ ] Peer code review with checklist validation
- [ ] Architecture compliance verification

### 5. Deployment Phase
Safe deployment to production.

- [ ] Database migration with rollback plan
- [ ] Gradual rollout with monitoring
- [ ] Post-deployment validation
- [ ] Documentation updates

## Rules
- SOLID principles and DDD architecture
- Exception handling instead of null returns
- Input validation with Bean Validation
- Comprehensive logging with SLF4J
- Security best practices
- MCP server usage: postgres, pg-aiguide, sonarlint, curl

## Checkpoints
- [ ] Feature requirements completed
- [ ] Unit tests passing (80%+ coverage)
- [ ] Integration tests passing
- [ ] Security review passed
- [ ] Code review approved