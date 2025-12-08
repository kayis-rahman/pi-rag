# Kilo Code Frontend Feature Development

Standardized workflow for implementing new frontend features using Kilo Code AI assistant.

## Trigger
- UI/UX feature requests
- Component development
- Platform-specific implementations
- User interaction enhancements

## Priority
High

## Estimated Duration
1-2 weeks

## Phases

### 1. Planning Phase
Plan the frontend feature implementation.

- [ ] UI/UX design review and validation
- [ ] Component architecture and data flow design
- [ ] State management strategy planning
- [ ] Accessibility and platform compatibility review

### 2. Implementation Phase
Implement the frontend feature following DDD architecture.

- [ ] **Domain Layer**: Create entities and value objects
- [ ] **Application Layer**: Implement ViewModels and use cases
- [ ] **Infrastructure Layer**: Set up networking and persistence
- [ ] **Presentation Layer**: Create SwiftUI views and components
- [ ] Add accessibility support and VoiceOver compliance

### 3. Testing Phase
Comprehensive frontend testing.

- [ ] Unit tests for business logic and models
- [ ] UI tests for user interactions
- [ ] Integration tests for API communication
- [ ] Accessibility testing and validation

### 4. Review Phase
Frontend code review and validation.

- [ ] SwiftLint code quality checks
- [ ] UI/UX design review and feedback
- [ ] Platform compatibility testing (iOS/macOS)
- [ ] Performance optimization review

### 5. Deployment Phase
Frontend deployment.

- [ ] TestFlight deployment and beta testing
- [ ] App Store submission preparation
- [ ] User acceptance testing
- [ ] Release notes and documentation

## Rules
- No force unwrapping (!)
- Proper error handling with guard statements
- Secure logging (mask sensitive data)
- SwiftUI best practices and accessibility
- Memory management (prefer structs, avoid singletons)
- MCP server usage: playwright, filesystem, memory

## Checkpoints
- [ ] UI components implemented
- [ ] Business logic implemented
- [ ] Unit tests passing
- [ ] UI tests passing
- [ ] Accessibility verified