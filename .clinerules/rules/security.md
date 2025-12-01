# Security Rules

Security rules applied across all languages and frameworks in TimeBeam.

## Input Validation
- **ALWAYS validate all inputs**
- **NEVER trust user input**
- **Use parameterized queries** for database operations
- **Sanitize all user inputs**

## Authentication & Authorization
- **ALWAYS verify user permissions**
- **NEVER hardcode credentials**
- **ALWAYS use secure token storage**
- **IMPLEMENT proper session management**

## Data Protection
- **ENCRYPT sensitive data at rest**
- **USE HTTPS for all communications**
- **MASK sensitive data in logs**
- **IMPLEMENT proper access controls**

## Dependency Security
- **REGULARLY update dependencies**
- **MONITOR for known vulnerabilities**
- **USE dependency scanning tools**
- **REVIEW changelog for security fixes**

## Examples

### Bad: SQL Injection
```java
String query = "SELECT * FROM users WHERE id = " + userId;
```

### Good: Parameterized Query
```java
String query = "SELECT * FROM users WHERE id = ?";
```

### Bad: Logging Sensitive Data
```javascript
console.log("User token:", userToken);
```

### Good: Masked Logging
```javascript
console.log("User authenticated:", maskToken(userToken));
