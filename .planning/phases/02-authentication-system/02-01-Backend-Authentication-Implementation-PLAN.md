---
phase: 02-Authentication-System
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - back-end/src/main/java/com/sparkage/timebeam/presentation/controller/AuthController.java
  - back-end/src/main/java/com/sparkage/timebeam/application/service/AuthService.java
  - back-end/src/main/java/com/sparkage/timebeam/domain/model/User.java
  - back-end/src/main/java/com/sparkage/timebeam/infrastructure/persistence/UserRepository.java
  - back-end/src/main/java/com/sparkage/timebeam/application/service/JwtService.java
  - back-end/src/main/java/com/sparkage/timebeam/application/service/impl/JwtServiceImpl.java
  - back-end/src/main/java/com/sparkage/timebeam/application/service/impl/AuthServiceImpl.java
  - back-end/src/main/java/com/sparkage/timebeam/infrastructure/config/SecurityConfig.java
autonomous: true
requirements:
  - AUTH-01
  - AUTH-02
  - AUTH-03
  - AUTH-04
user_setup: []

must_haves:
  truths:
    - Users can register and log in using Google Sign-In
    - JWT tokens are generated and validated for API access
    - Token storage is secure on client devices
    - User accounts are properly created and linked to email addresses
  artifacts:
    - path: "back-end/src/main/java/com/sparkage/timebeam/presentation/controller/AuthController.java"
      provides: "Authentication API endpoints"
      exports: ["POST /api/auth/register", "POST /api/auth/login"]
    - path: "back-end/src/main/java/com/sparkage/timebeam/application/service/AuthService.java"
      provides: "Authentication business logic"
      exports: ["registerUser", "authenticateUser"]
    - path: "back-end/src/main/java/com/sparkage/timebeam/application/service/JwtService.java"
      provides: "JWT token generation and validation"
      exports: ["generateToken", "validateToken"]
    - path: "back-end/src/main/java/com/sparkage/timebeam/domain/model/User.java"
      provides: "User data model"
      contains: "User entity with email, display_name, is_admin"
  key_links:
    - from: "back-end/src/main/java/com/sparkage/timebeam/presentation/controller/AuthController.java"
      to: "back-end/src/main/java/com/sparkage/timebeam/application/service/impl/AuthServiceImpl.java"
      via: "dependency injection"
      pattern: "Autowired.*AuthService"
    - from: "back-end/src/main/java/com/sparkage/timebeam/application/service/impl/AuthServiceImpl.java"
      to: "back-end/src/main/java/com/sparkage/timebeam/application/service/JwtService.java"
      via: "token generation"
      pattern: "jwtService.generateToken"
    - from: "back-end/src/main/java/com/sparkage/timebeam/application/service/impl/AuthServiceImpl.java"
      to: "back-end/src/main/java/com/sparkage/timebeam/infrastructure/persistence/UserRepository.java"
      via: "user persistence"
      pattern: "userRepository.save"
---

<objective>
Implement the backend authentication system with Google Sign-In integration and JWT-based authorization.
</objective>

<execution_context>
@/Users/kayisrahman/.claude/get-shit-done/workflows/execute-plan.md
@/Users/kayisrahman/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/REQUIREMENTS.md

# Authentication system requirements
The system must support:
- Google Sign-In integration for user authentication
- JWT-based authentication system with secure token management
- Secure token storage and management on client devices
- User registration and login functionality
- Protected API endpoints requiring authentication

# Backend stack
- Spring Boot 3.x
- Java 17+
- PostgreSQL database (H2 for testing)
- Maven build system
</context>

<tasks>

<task type="auto">
  <name>Task 1: Create JWT Service interface and implementation</name>
  <files>back-end/src/main/java/com/sparkage/timebeam/application/service/JwtService.java</files>
  <action>Create JWT service interface with methods for token generation and validation. Then implement it with the jose library for secure JWT handling. The implementation should:
1. Generate secure JWT tokens with user details and expiration (15 minutes for access token)
2. Validate JWT tokens and extract user information
3. Use HS256 signing algorithm for security
4. Include standard claims (subject, issuer, issuedAt, expiration)
5. Handle token expiration gracefully
</action>
  <verify>File exists with interface and implementation, test JwtService methods</verify>
  <done>JWT service properly created with generate and validate methods, tests passing</done>
</task>

<task type="auto">
  <name>Task 2: Implement authentication service</name>
  <files>back-end/src/main/java/com/sparkage/timebeam/application/service/impl/AuthServiceImpl.java</files>
  <action>Create authentication service implementation with:
1. User registration logic that creates new users from Google Sign-In data
2. User login logic that validates Google Sign-In and generates JWT tokens
3. User lookup functionality by email
4. Password handling (store hashed passwords using BCrypt)
5. Token generation and management using JWT service
6. Error handling for duplicate emails, invalid credentials, etc.
</action>
  <verify>File exists with AuthServiceImpl class implementing all methods, tests pass</verify>
  <done>Authentication service correctly registers and logs in users, generates valid JWT tokens</done>
</task>

<task type="auto">
  <name>Task 3: Create authentication controller</name>
  <files>back-end/src/main/java/com/sparkage/timebeam/presentation/controller/AuthController.java</files>
  <action>Create REST controller for authentication endpoints:
1. POST /api/auth/register - Accepts Google Sign-In payload with email and display_name, calls AuthService to register user
2. POST /api/auth/login - Accepts Google Sign-In payload, calls AuthService to authenticate and return JWT
3. Implement proper request/response DTOs for these endpoints
4. Add proper exception handling and HTTP status codes
5. Configure endpoint security to allow unauthenticated access to these endpoints
</action>
  <verify>Controller created with both endpoints, accepts proper JSON payloads, returns correct HTTP responses</verify>
  <done>Authentication endpoints accept Google Sign-In data, register and authenticate users, return JWT tokens</done>
</task>

</tasks>

<verification>
[Overall phase checks]
1. All authentication endpoints are accessible and functional
2. JWT tokens are properly generated and validated
3. User registration and login work as expected
4. Security configuration properly protects authenticated endpoints
5. All error cases are handled gracefully
</verification>

<success_criteria>
[Measurable completion]
1. POST /api/auth/register accepts Google Sign-In data and creates user in database
2. POST /api/auth/login accepts Google Sign-In data and returns valid JWT token
3. JWT tokens are properly signed and have 15-minute expiration
4. User data is securely stored with BCrypt-hashed passwords
5. API endpoints return appropriate HTTP status codes (201 for registration, 200 for login)
</success_criteria>

<output>
After completion, create `.planning/phases/02-Authentication-System/02-01-Backend-Authentication-Implementation-SUMMARY.md`
</output>