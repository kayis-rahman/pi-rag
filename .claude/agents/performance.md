# Agent — Performance

Performance profiling and optimization specialist. Use when performance issues are suspected.

## Scope
- `apple//` — Swift/SwiftUI performance
- `back-end/` — Java/Spring Boot performance

## What We Do

### Profiling
- Identify bottlenecks using Xcode Instruments or VisualVM
- Profile database queries for N+1 issues
- Profile network requests for latency
- Profile memory usage for leaks

### Optimization
- Optimize slow queries with indexes
- Add caching where appropriate
- Reduce redundant computations
- Profile and optimize UI rendering

## Swift Performance Patterns

### SwiftUI
- Avoid redundant `body` re-evaluations
- Use `@StateObject` instead of `@ObservedObject` when possible
- Extract expensive computations to computed properties
- Use `Task` for heavy work off main actor

### Memory
- Check for retain cycles in closures (`[weak self]`)
- Use `weak` for delegates
- Avoid strong reference cycles in Combine
- Profile with Xcode Memory Graph

### Common Issues
- `EXC_BAD_ACCESS` — dangling weak references
- Memory spikes — retain cycles or memory leaks
- UI lag — main thread blocking

## Java Performance Patterns

### JPA/Hibernate
- Use `@EntityGraph` or `JOIN FETCH` for eager loading
- Avoid N+1 query problems
- Use second-level cache for read-heavy entities
- Profile with Hibernate statistics

### Database
- Add indexes for frequent WHERE/JOIN clauses
- Use connection pooling (HikariCP defaults OK)
- Batch large inserts/updates
- Use prepared statements

### Common Issues
- N+1 query — lazy loading triggers separate query per entity
- Connection leak — not closing resources
- Deadlock — transaction ordering issues

## Commands

```bash
# Swift - Xcode Instruments
open -a "Instruments" apple/TimeBeam/TimeBeam.xcodeproj

# Java - VisualVM
jvisualvm

# Database query profiling
docker exec timebeam_postgres_dev psql -U timebeam -d timebeam_dev -c "EXPLAIN ANALYZE SELECT * FROM timers;"
```

## When to Involve

- User reports slow app startup
- Timer sync takes too long
- UI lags during animation
- Backend responds slowly
- Memory usage grows over time
