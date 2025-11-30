Goal

Create a single, copy-pastable AI prompt an iOS developer (or an AI assistant that writes Swift code) can use to implement integration between the TimeBeam iOS app and the existing Java backend.

The prompt must follow Apple idioms and project structure (Swift, SPM, URLSession, Codable, Keychain storage, XCTest), include exact JSON shapes expected by the backend, list API endpoints and HTTP methods, describe authentication handling, error handling and logging, outline files to create, and include unit/integration test guidance.

---

AI PROMPT (deliver to an AI assistant or developer):

You are an iOS engineer. Implement backend integration for the TimeBeam iOS application so it can authenticate users and manage sessions with the existing Java backend. Produce complete, ready-to-add Swift source files, tests, and short setup instructions. Use modern Apple patterns and project layout (Swift 5, iOS 16+, Swift Package Manager friendly). Keep platform security and App Store guidelines in mind.

Repository context (what the backend expects)
- Backend base URL: configurable via environment/Cocoa configuration. Example: https://api.timebeam.example (use /api base path)
- Relevant endpoints (JSON request/response shapes):
  - POST /api/auth/login
    - Request body: { "email": "user@example.com" }
    - Response (200): { "accessToken": "<jwt-token>" }
    - Response (401): { "error": "invalid_credentials" }
  - POST /api/auth/register
    - Request body: { "email": "user@example.com", "displayName": "Alice" }
    - Response (200): User DTO (id, email, displayName — follow backend UserDto if available)
  - POST /api/sessions/start?kind={WORK|SHORT_BREAK|LONG_BREAK}
    - Requires Authorization: Bearer <token>
    - Response (201): SessionRecordDto
  - POST /api/sessions/{id}/stop
    - Requires Authorization
    - Response (200): SessionRecordDto (durationSeconds updated)
  - GET /api/sessions
    - Requires Authorization
    - Response (200): [SessionRecordDto]
  - POST /api/sessions (create) and DELETE /api/sessions/{id}

- SessionRecordDto JSON shape (map to Swift Codable):
  {
    "id": "75f55ecc-bd6d-401b-873a-ee11e74970c5",
    "userId": "5b79ac8f-4bf9-4214-a51a-1ceaa1de3d48",
    "startedAt": "2025-11-18T10:00:00Z",
    "durationSeconds": 1500,
    "kind": "WORK"
  }

Requirements and constraints
- Networking: Use URLSession (no third-party networking libs). Implement a reusable APIClient and an AuthInterceptor that attaches Authorization header when token exists.
- Models: Create Swift Codable structs matching backend DTOs (SessionRecord, Auth requests/responses, UserDto minimal fields).
- Persistence: Store accessToken securely using Keychain. Provide a small Keychain wrapper with safe defaults.
- Google Sign-In flow: Use the official GoogleSignIn SDK (SPM). After successful sign-in, obtain the user's email and call backend POST /api/auth/login (body {"email"}). If backend returns 200 with accessToken, store it in Keychain and proceed. If backend returns 401, surface a user-friendly message. Include guidance on configuring URL types / reversed client ID and the steps to add the SDK.
- Error handling: Normalize network errors and backend error payloads into a small Error enum that can be used across the app. Log at debug/info levels using os_log where appropriate.
- Concurrency: Use async/await APIs for networking and higher-level services.
- Tests: Add XCTest unit tests for the network layer and AuthService using URLProtocol stubs to simulate backend responses. Write at least: (1) login success returning token, (2) login 401 invalid_credentials, (3) start session returns created session, (4) stop session updates duration.
- File structure (suggested) to add to the Xcode project or SPM package:
  - Sources/TimeBeamNetwork/
    - APIClient.swift
    - AuthService.swift
    - SessionService.swift
    - Models/
      - SessionRecord.swift
      - AuthModels.swift
    - Utils/
      - KeychainStorage.swift
      - NetworkError.swift
  - Tests/TimeBeamNetworkTests/
    - APIClientTests.swift
    - AuthServiceTests.swift
    - SessionServiceTests.swift

Deliverables (what you must produce)
1. Swift source files for APIClient, AuthService, SessionService, models and Keychain wrapper.
2. Unit tests using XCTest and URLProtocol-based stubs for the network responses.
3. Short README snippet with Google Sign-In setup steps and how to configure base API URL and run tests.

Acceptance criteria
- Provided Swift files compile (Swift 5.8+, iOS 16+) and use async/await.
- Unit tests execute and cover happy path and main error path for auth and session start/stop.
- The AuthService uses GoogleSignIn to obtain the user's email and then exchanges it with the backend login endpoint.
- The APIClient appends Authorization header as "Authorization: Bearer <token>" for protected endpoints.

Behavioral details (implementation notes)
- APIClient:
  - Provide a shared instance or dependency-injectable initializer that takes a baseURL and KeychainStorage.
  - Implement a request<T: Decodable>(_:method:path:query:body:headers:) async throws -> T method that builds URLRequest, serializes JSON bodies using JSONEncoder (ISO-8601 for dates), and decodes using JSONDecoder configured for ISO-8601 timestamps.
  - When receiving non-2xx responses, decode backend error body {"error": "invalid_credentials"} when present and throw an appropriate NetworkError.
- AuthService:
  - Public API: loginWithEmail(email: String) async throws -> Void (stores token)
  - Public API: loginWithGoogle(presentingViewController: UIViewController) async throws -> Void (uses GoogleSignIn and then exchanges email with login endpoint)
  - Public API: currentAccessToken() -> String?
  - Public API: logout() -> Void (removes token from keychain)
- SessionService:
  - startSession(kind: String) async throws -> SessionRecord
  - stopSession(id: UUID) async throws -> SessionRecord
  - listSessions() async throws -> [SessionRecord]
- KeychainStorage:
  - Minimal get/set/remove for String values keyed by a service/key pair. Use SecItemAdd/Update/CopyMatching.
- Tests:
  - Use a custom URLProtocol subclass to intercept and return pre-canned responses for given request paths and methods.
  - Mock the KeychainStorage in tests to avoid manipulating actual keychain.

Security and privacy notes
- Never log full email addresses or tokens at info level. Use masked emails for info logs and full emails only at debug if necessary (and never in production logs).

Example JSON usage snippets (for developer convenience)
- Start session request (server uses query param):
  POST /api/sessions/start?kind=WORK
  Authorization: Bearer <token>
  Response 201 body: SessionRecordDto JSON above

- Stop session request:
  POST /api/sessions/75f55ecc-bd6d-401b-873a-ee11e74970c5/stop
  Authorization: Bearer <token>
  Response 200 body: SessionRecordDto with durationSeconds set

README snippet for GoogleSignIn (brief)
1. Add GoogleSignIn via Swift Package Manager: https://github.com/google/GoogleSignIn-iOS
2. Add reversed client ID to URL Types in project settings (from GoogleService-Info.plist).
3. Configure the sign-in button in UI and call AuthService.loginWithGoogle(presentingViewController:).
4. After sign-in the AuthService exchanges email for backend accessToken and stores it securely in Keychain.

Wrap up
Return a set of concrete Swift files, unit tests, and the short README instructions. Ensure the code is idiomatic, well-documented and uses async/await and Codable. Include small comments near security-sensitive operations describing why they are implemented that way.

---

Notes
- This prompt is intentionally prescriptive: the goal is that an AI assistant or developer should be able to take it and produce a working iOS integration that uses the backend endpoints described above. Adjust base URL and minor DTO fields to match the TimeBeam backend as needed.
