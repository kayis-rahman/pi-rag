"""
Sample documents for testing.

Provides reusable sample documents for unit and integration tests.
"""

# Sample README
SAMPLE_README = """# SYNAPSE RAG System

SYNAPSE is a local RAG system for AI agents, providing semantic memory,
episodic memory, and symbolic memory capabilities.

## Features

- **Semantic Memory**: Document retrieval with vector embeddings
- **Episodic Memory**: Agent learning from experience
- **Symbolic Memory**: Facts, preferences, and constraints

## Quick Start

```bash
pip install synapse
synapse setup
synapse start
```

## Configuration

Edit `configs/synapse_config.json` to customize:
- Chunk size and overlap
- Top-K retrieval settings
- Model paths
- Memory settings

## Usage

Ingest your codebase:

```bash
synapse ingest ./src
```

Query your knowledge base:

```bash
synapse query "How does authentication work?"
```

## License

MIT License
"""

# Sample Python Code
SAMPLE_PYTHON_CODE = """
\"\"\"
Authentication module for SYNAPSE.

Provides OAuth2-based user authentication with token validation.
\"\"\"

import secrets
from typing import Optional


class AuthenticationError(Exception):
    \"\"\"Raised when authentication fails.\"\"\"


class OAuth2Token:
    \"\"\"OAuth2 token object.\"\"\"

    def __init__(self, access_token: str, refresh_token: str, expires_in: int):
        self.access_token = access_token
        self.refresh_token = refresh_token
        self.expires_in = expires_in


def authenticate_user(username: str, password: str) -> OAuth2Token:
    \"\"\"
    Authenticate a user with username and password.

    Args:
        username: User's username or email
        password: User's password

    Returns:
        OAuth2Token object with access and refresh tokens

    Raises:
        AuthenticationError if credentials are invalid
    \"\"\"
    if not username or not password:
        raise AuthenticationError("Username and password required")

    # Validate credentials
    if not validate_credentials(username, password):
        raise AuthenticationError("Invalid credentials")

    # Generate tokens
    access_token = secrets.token_urlsafe(32)
    refresh_token = secrets.token_urlsafe(32)

    return OAuth2Token(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=3600  # 1 hour
    )


def validate_credentials(username: str, password: str) -> bool:
    \"\"\"Validate user credentials.\"\"\"
    # In production, check against database
    return len(password) >= 8


def refresh_token(token: str) -> OAuth2Token:
    \"\"\"Refresh an OAuth2 token.\"\"\"
    # Validate refresh token
    if not token or len(token) < 20:
        raise AuthenticationError("Invalid refresh token")

    # Generate new tokens
    access_token = secrets.token_urlsafe(32)
    refresh_token = secrets.token_urlsafe(32)

    return OAuth2Token(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=3600
    )
"""

# Sample JSON Configuration
SAMPLE_CONFIG = """{
  "chunk_size": 500,
  "chunk_overlap": 50,
  "top_k": 3,
  "min_retrieval_score": 0.3,
  "query_expansion_enabled": true,
  "num_expansions": 3,
  "embedding_model": "bge-m3-q8_0.gguf",
  "chat_model": "gemma-3-1b-it-UD-Q4_K_XL.gguf",
  "temperature": 0.7,
  "max_tokens": 2048,
  "memory_enabled": true,
  "semantic_memory_enabled": true,
  "episodic_memory_enabled": true,
  "symbolic_memory_enabled": true
}"""

# Sample Markdown Documentation
SAMPLE_DOCUMENTATION = """# Authentication Guide

## Overview

SYNAPSE uses OAuth2 for authentication. This provides secure, industry-standard
authentication with support for access tokens, refresh tokens, and token
revocation.

## Authentication Flow

### 1. User Login

```python
from synapse.auth import authenticate_user

token = authenticate_user("user@example.com", "password123")
print(f"Access token: {token.access_token}")
```

### 2. Access Protected Resources

Use the access token in the Authorization header:

```bash
curl -H "Authorization: Bearer {access_token}" \\
     https://api.synapse.dev/v1/query
```

### 3. Refresh Token

When the access token expires, use the refresh token to get a new one:

```python
from synapse.auth import refresh_token

new_token = refresh_token(refresh_token)
```

## Token Security

- Access tokens expire after 1 hour
- Refresh tokens are long-lived but can be revoked
- Store tokens securely (use environment variables or secure storage)
- Never expose tokens in client-side code

## Error Handling

```python
from synapse.auth import AuthenticationError

try:
    token = authenticate_user(username, password)
except AuthenticationError as e:
    print(f"Authentication failed: {e}")
```

## Best Practices

1. Always use HTTPS in production
2. Implement rate limiting to prevent brute-force attacks
3. Use strong password policies
4. Log all authentication attempts for security auditing
5. Implement token rotation for enhanced security
"""

# Sample Plain Text
SAMPLE_TEXT = """
The SYNAPSE RAG system provides three types of memory:

1. Semantic Memory - Stores documents and code with vector embeddings
2. Episodic Memory - Stores agent experiences and lessons learned
3. Symbolic Memory - Stores facts, preferences, and constraints

Each memory type has a different authority level:
- Symbolic Memory: 100% (authoritative)
- Episodic Memory: 85% (advisory)
- Semantic Memory: 60% (non-authoritative)

Memory is queried using the following hierarchy:
1. Check symbolic memory for facts
2. Check episodic memory for lessons
3. Check semantic memory for documents

This ensures that authoritative facts take precedence over suggestions
from episodic or semantic memory.
"""

# Sample YAML Configuration
SAMPLE_YAML = """# SYNAPSE Configuration

# RAG Settings
chunk_size: 500
chunk_overlap: 50
top_k: 3
min_retrieval_score: 0.3

# Query Expansion
query_expansion_enabled: true
num_expansions: 3
expansion_method: semantic

# Models
embedding_model: bge-m3-q8_0.gguf
chat_model: gemma-3-1b-it-UD-Q4_K_XL.gguf
temperature: 0.7
max_tokens: 2048

# Memory Settings
memory_enabled: true
semantic_memory_enabled: true
episodic_memory_enabled: true
symbolic_memory_enabled: true

# Server Settings
mcp_port: 8002
mcp_host: 0.0.0.0
"""

# Sample Toml Configuration
SAMPLE_TOML = """[synapse]
name = "SYNAPSE RAG System"
version = "1.2.0"

[rag]
chunk_size = 500
chunk_overlap = 50
top_k = 3
min_retrieval_score = 0.3

[rag.query_expansion]
enabled = true
num_expansions = 3
method = "semantic"

[models]
embedding = "bge-m3-q8_0.gguf"
chat = "gemma-3-1b-it-UD-Q4_K_XL.gguf"
temperature = 0.7
max_tokens = 2048

[memory]
enabled = true
semantic = true
episodic = true
symbolic = true

[server]
mcp_port = 8002
mcp_host = "0.0.0.0"
"""

# Sample JavaScript Code
SAMPLE_JAVASCRIPT = """
/**
 * SYNAPSE Authentication Module
 * Provides OAuth2 authentication for SYNAPSE clients
 */

class AuthenticationError extends Error {
    constructor(message) {
        super(message);
        this.name = 'AuthenticationError';
    }
}

class OAuth2Token {
    constructor(accessToken, refreshToken, expiresIn) {
        this.accessToken = accessToken;
        this.refreshToken = refreshToken;
        this.expiresIn = expiresIn;
    }

    isExpired() {
        return this.expiresIn <= 0;
    }
}

async function authenticate(username, password) {
    if (!username || !password) {
        throw new AuthenticationError('Username and password required');
    }

    // Validate credentials
    const isValid = await validateCredentials(username, password);
    if (!isValid) {
        throw new AuthenticationError('Invalid credentials');
    }

    // Generate tokens
    const accessToken = generateAccessToken();
    const refreshToken = generateRefreshToken();

    return new OAuth2Token(accessToken, refreshToken, 3600);
}

async function validateCredentials(username, password) {
    // In production, validate against backend
    return password.length >= 8;
}

function generateAccessToken() {
    return Math.random().toString(36).substring(2, 15) +
           Math.random().toString(36).substring(2, 15);
}

function generateRefreshToken() {
    return Math.random().toString(36).substring(2, 15) +
           Math.random().toString(36).substring(2, 15);
}

module.exports = {
    AuthenticationError,
    OAuth2Token,
    authenticate,
    validateCredentials,
};
"""

# Document types registry
SAMPLE_DOCUMENTS = {
    "readme": SAMPLE_README,
    "python": SAMPLE_PYTHON_CODE,
    "config": SAMPLE_CONFIG,
    "documentation": SAMPLE_DOCUMENTATION,
    "text": SAMPLE_TEXT,
    "yaml": SAMPLE_YAML,
    "toml": SAMPLE_TOML,
    "javascript": SAMPLE_JAVASCRIPT,
}
