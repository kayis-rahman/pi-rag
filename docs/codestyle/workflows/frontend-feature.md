# Frontend Feature Development

Standardized workflow for implementing new frontend features in TimeBeam.

## Trigger
- Files: `apple/**/*.swift`, `TimeBeamShared/**/*.swift`

## Priority
High

## Estimated Duration
1-2 weeks

## Phases

### 1. Planning Phase
Plan frontend feature implementation.

- [ ] UI/UX design review and validation
- [ ] Component architecture and data flow design
- [ ] State management strategy planning
- [ ] Accessibility and platform compatibility review

### 2. Implementation Phase
Implement frontend feature following DDD architecture.

- [ ] **Domain Layer**: Create entities and value objects in `Domain/Models/`
- [ ] **Application Layer**: Implement ViewModels and use cases in `Application/ViewModels/`
- [ ] **Infrastructure Layer**: Set up networking and persistence in `Infrastructure/`
- [ ] **Presentation Layer**: Create SwiftUI views and components in `Presentation/Views/`
- [ ] Add accessibility support and VoiceOver compliance throughout

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
- SwiftUI best practices
- Accessibility compliance
- **MCP server usage: playwright, filesystem, memory**

## Checkpoints
- [ ] UI components implemented
- [ ] Business logic implemented
- [ ] Unit tests passing
- [ ] UI tests passing
- [ ] Accessibility verified
