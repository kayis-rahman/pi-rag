# Common Security Patterns

> Shared security patterns for TimeBeam project.

## Secret Management

- NEVER hardcode secrets in source code
- API keys, tokens, passwords → environment variables
- Keychain for client-side token storage (Security.framework)
- `.env` files → `.gitignore`
- `settings.local.json` → `.gitignore`

## iOS/macOS Security

- Keychain for JWT token storage
- Keychain access group from entitlements (`425MSY8FLG.com.sparkage.time-beam`)
- FaceID/TouchID for sensitive operations
- Never log tokens or credentials
- TLS for all network requests
- Certificate pinning for production
- Keychain error -34018 = missing entitlements, not a code bug

## Backend Security

- JWT tokens: signed with HMAC/RS256, short expiry
- Password hashing: BCrypt (Spring Security)
- CORS: restrict to known origins
- Rate limiting on auth endpoints
- SQL injection: use parameterized queries (JPA prevents this)
- XSS: sanitize user input in any HTML output

## API Security

- Authentication required for all endpoints except health/auth
- Role-based access control (RBAC)
- Token refresh flow: access token + refresh token
- Validate PKCE flow for OAuth
- Input validation on all DTOs (`@Valid`, `@NotNull`, `@Size`)

## OWASP Top 10

- A01: Broken access control — validate user owns resource
- A02: Cryptographic failures — use Keychain, not UserDefaults
- A03: Injection — JPA prevents SQLi, validate all input
- A05: Security misconfiguration — secure defaults, no debug in prod
- A07: Auth failures — JWT validation, token expiry, refresh flow

## Common Vulnerabilities to Check

- Hardcoded API keys in Swift/Java source
- UserDefaults for tokens (use Keychain)
- `allowAllCertificates` or `NSURLSessionConfiguration` with bypass
- SQL string concatenation in native queries
- Unvalidated OAuth callbacks
- Missing CORS configuration
