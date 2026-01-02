# Swift Clean Code Rules

Language-specific rules for Swift/SwiftUI development in TimeBeam.

## Domain-Driven Design (DDD) Structure

### Recommended Folder Structure for iOS App
```
TimeBeam/
├── Domain/                   # Domain Layer
│   ├── Models/              # Entities, Value Objects, Aggregates
│   ├── Services/            # Domain Services
│   ├── Events/              # Domain Events
│   └── Repositories/        # Repository Protocols
├── Application/              # Application Layer
│   ├── ViewModels/          # ViewModels, Use Cases
│   ├── Coordinators/        # Navigation Coordinators
│   └── DTOs/                # Application DTOs
├── Infrastructure/           # Infrastructure Layer
│   ├── Networking/          # API Clients, Services
│   ├── Persistence/         # Core Data, Storage
│   ├── External/            # Third-party Integrations
│   └── Config/              # Configuration
└── Presentation/             # Presentation Layer
    ├── Views/               # SwiftUI Views
    ├── ViewControllers/     # UIKit View Controllers
    └── Components/          # Reusable UI Components
```

### Recommended Folder Structure for Shared Code
```
TimeBeamShared/
├── Domain/                  # Cross-platform domain logic
│   ├── Models/             # Shared entities and value objects
│   └── Services/           # Domain services
├── Application/             # Shared application services
│   └── DTOs/               # Cross-platform DTOs
├── Infrastructure/          # Platform-agnostic infrastructure
└── Presentation/            # Shared UI components
```

### Layer Responsibilities
- **Domain**: Business logic, rules, and constraints
- **Application**: Orchestrates domain objects for use cases
- **Infrastructure**: Technical implementations (networking, persistence)
- **Presentation**: User interface and external interactions

## Force Unwrapping
- **NEVER use `!`** for force unwrapping
- **ALWAYS use optional binding** (`guard let` or `if let`)
- **ALWAYS handle error cases** properly

## Examples

### Bad: Force unwrapping
```swift
let value = optionalValue!
```

### Good: Safe optional handling
```swift
guard let value = optionalValue else {
    throw SomeError.valueMissing
}
```

## Logging Security
- **NEVER log sensitive data** (emails, tokens, passwords)
- **ALWAYS use private logging** for sensitive information
- **ALWAYS mask sensitive data** before logging

### Bad: Logging sensitive data
```swift
os_log("User: %{public}@", email)
```

### Good: Masking sensitive data
```swift
os_log("User: %{private}@", maskEmail(email))
```

## Memory Management
- **Prefer structs** over classes for data models
- **Use weak references** to avoid retain cycles
- **Avoid singleton patterns** unless absolutely necessary

## Error Handling
- **Define custom Error enums** for different error types
- **Use Result types** for operations that can fail
- **Avoid force try** - use do-catch or optional try

## SwiftUI Best Practices
- **Use declarative syntax** for UI
- **Separate view logic** from business logic
- **Use appropriate state management** (@State, @ObservedObject, etc.)
- **Implement accessibility** support
- **Follow platform guidelines** (iOS/macOS)
