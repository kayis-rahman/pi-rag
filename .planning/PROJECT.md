# TimeBeam

## What This Is

TimeBeam is a cross-platform productivity application featuring synchronized timer functionality across iOS and macOS devices. The system provides real-time synchronization of timer states with sophisticated conflict resolution, secure authentication, and comprehensive analytics capabilities. Users can work with Pomodoro-style work/break cycles while their timer state stays synchronized across all their devices.

## Core Value

A single Pomodoro timer state that stays synchronized across all devices in real-time, with conflict resolution that ensures users always see the most current state regardless of which device initiated the change.

## Requirements

### Validated

- ✓ Project scaffolding established — Phase 1, SETUP-01
- ✓ Database schema configured (users, sessions, timer_states tables) — Phase 1, SETUP-02
- ✓ API endpoints defined and implemented — Phase 1, SETUP-03
- ✓ iOS/macOS app structure created with SwiftUI — Phase 1, SETUP-04
- ✓ Backend Spring Boot setup with Maven — Phase 1, SETUP-05

### Active

- [ ] AUTH-01: User can sign in with Google OAuth
- [ ] AUTH-02: User can sign in with Apple Sign-In
- [ ] AUTH-03: JWT tokens issued and validated
- [ ] AUTH-04: Secure token storage in Keychain
- [ ] SYNC-01: Timer state synchronized across devices
- [ ] SYNC-02: Event-based sync for timer actions
- [ ] SYNC-03: Conflict resolution with timestamp priority
- [ ] SYNC-04: Device identification and feedback loop prevention
- [ ] SYNC-05: Background synchronization with timeout protection
- [ ] SYNC-06: State polling with network resilience
- [ ] ANALYTICS-01: Session recording with work/break tracking
- [ ] ANALYTICS-02: Productivity streak calculation
- [ ] ANALYTICS-03: Top productive window analysis

### Out of Scope

- Mobile app watchOS support — Currently inUITests only, not production app
- Web-based client — Cross-platform limited to iOS/macOS native apps
- Real-time WebSocket push — State polling only (30+ second intervals)
- Multi-user collaborative timer — Single timer per user only

## Context

**Technical Environment:**
- iOS/macOS: Swift 5.9+, SwiftUI, Swift Concurrency, Xcode 15+
- Backend: Java 17, Spring Boot 3.2.0, PostgreSQL 15+
- Build: Maven for backend, Xcode for iOS/macOS

**User Base:**
- Single-user productivity tracking
- Cross-device synchronization for users with multiple Apple devices
- Focus on Pomodoro technique users

**Known Issues to Address:**
- Token revocation not implemented (security gap)
- JWT secret uses default "change-me" value in dev config
- Timer state not persisted across app restarts
- Debug print statements may expose tokens in dev builds
- No automatic token refresh before expiration
- No pagination on session list endpoint

## Constraints

- **Timeline:** V1 launch with core timer sync and authentication
- **Tech Stack:** Swift for mobile, Java/Spring Boot for backend
- **Database:** PostgreSQL for persistence
- **Authentication:** Google OAuth + Apple Sign-In + JWT
- **Platforms:** iOS 15+, macOS 12+ (Apple ecosystem only)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Phase-based planning with GSD | Clear roadmap, measurable milestones | 6 phases planned for V1 |
| Token revocation deferred | Not critical for V1, can be added later | Security gap documented |
| State polling over WebSockets | Simpler implementation, adequate for timer sync | 30+ second sync interval |
| Timestamp-based conflict resolution | Simple, deterministic, works for timer state | May need improvement for clock skew |

---
*Last updated: 2026-04-20 after codebase mapping*

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state (users, feedback, metrics)
