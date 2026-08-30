# Synapse Backend

Overview
--------
This is a production-ready Spring Boot 3 backend (Java 17) for the Synapse Apple cross-platform app. It follows a clean, layered architecture:

- com.sparkage.synapse
  - controller — REST controllers (api surface)
  - service — business logic
  - repository — Spring Data JPA repositories
  - model — JPA entities
  - dto — API DTOs
  - mapper — MapStruct mappers
  - config — Spring configuration (security)
  - security — JWT utilities & filter
  - exception — global exception handling

Key features implemented
- Authentication (register, login + JWT issuance) — simplified for Google Sign-In flow (backend accepts email only)
- Session records (create, list, delete)
- Analytics helpers (last 7-day totals, streak, top productive window)
- Refresh token model and basic repository (prepared for refresh flows)
- PostgreSQL via Spring Data JPA (production) and H2 in tests
- MapStruct for mapping between JPA models and DTOs
- Validation with Jakarta Validation
- OpenAPI (springdoc) enabled
- Unit tests (JUnit 5 + Mockito)

API Endpoints
-------------
Base URL: `{{baseUrl}}` (Postman env variable)

Auth (public)
- POST /api/auth/register
  - Body: { "email": "you@example.com", "displayName": "You" }
  - Response: { "id":"<uuid>", "email":"you@example.com", "displayName":"You" }
- POST /api/auth/login
  - Body: { "email": "you@example.com" }
  - Response: { "accessToken": "<jwt>" }

Sessions (authenticated)
- POST /api/sessions
  - Headers: Authorization: Bearer {{jwtToken}}
  - Body: { "startedAt": "2025-11-03T10:00:00Z", "durationSeconds": 1500, "kind": "WORK" }
  - Response: saved SessionRecord DTO with id, userId
- GET /api/sessions
  - Headers: Authorization: Bearer {{jwtToken}}
  - Response: list of session record DTOs
- DELETE /api/sessions/{id}
  - Headers: Authorization: Bearer {{jwtToken}}
  - Response: 204 No Content

Analytics (accepts SessionRecordDto list) — useful for client-side analytics
- POST /api/analytics/last7days?tz=UTC
  - Body: [ SessionRecordDto, ... ]
  - Response: daily totals array for last 7 days
- POST /api/analytics/streak?tz=UTC
  - Body: [ SessionRecordDto, ... ]
  - Response: integer productive streak
- POST /api/analytics/top-window?windowHours=2&tz=UTC
  - Body: [ SessionRecordDto, ... ]
  - Response: top window (startHour, endHour, sessionCount)

Example DTO shapes
------------------
SessionRecordDto
{
  "id": "<uuid>",
  "userId": "<uuid>",
  "startedAt": "2025-11-03T10:00:00Z",
  "durationSeconds": 1500,
  "kind": "WORK"
}

UserDto
{
  "id": "<uuid>",
  "email": "you@example.com",
  "displayName": "You"
}

Database schema overview
------------------------
Tables (JPA entity names -> SQL):

users
- id UUID PRIMARY KEY
- email VARCHAR UNIQUE NOT NULL
- display_name VARCHAR NOT NULL
- is_admin BOOLEAN NOT NULL

session_records
- id UUID PRIMARY KEY
- user_id UUID NOT NULL (FK to users.id in production)
- started_at TIMESTAMP
- duration_seconds BIGINT
- kind VARCHAR (WORK/SHORT_BREAK/LONG_BREAK)

refresh_tokens
- id UUID PRIMARY KEY
- user_id UUID NOT NULL
- token VARCHAR UNIQUE NOT NULL
- expires_at TIMESTAMP

Note: Foreign-key creation is intentionally left permissive in early migrations to avoid environment constraints — add the FK in production migrations when DB schema is managed and consistent.

Setup & run (local)
-------------------
Prerequisites:
- Java 17 or later
- Maven 3.8+
- PostgreSQL (production) or use H2 for tests

1) Configure application.yml (src/main/resources/application.yml) or provide environment variables.

Important environment variables used by the application:
- SPRING_DATASOURCE_URL (jdbc:postgresql://host:port/db)
- SPRING_DATASOURCE_USERNAME
- SPRING_DATASOURCE_PASSWORD
- JWT_SECRET (a sufficiently long random secret)
- JWT_EXPIRATION_MS (token lifetime in ms)

2) Build

```bash
cd back-end
mvn clean package -DskipTests
```

3) Run (development)

```bash
# with environment variables
export JWT_SECRET="change-me-to-a-secure-random-string"
export SPRING_DATASOURCE_URL="jdbc:postgresql://localhost:5432/synapse"
export SPRING_DATASOURCE_USERNAME="postgres"
export SPRING_DATASOURCE_PASSWORD="password"

mvn -f back-end spring-boot:run
```

Or run the packaged jar:

```bash
java -jar back-end/target/synapse-backend-0.0.1-SNAPSHOT.jar
```

Testing
-------
- Unit tests: `mvn -f back-end test`
- Integration tests use H2 in-memory DB (configured in test scope)

Postman collection
------------------
A Postman collection with example requests and environment variables is included: `back-end/postman_synapse_collection.json`.

Docker (build & run)
--------------------
A `Dockerfile` is provided. To build and run locally:

```bash
docker build -t synapse-backend:latest back-end
docker run -e SPRING_DATASOURCE_URL=jdbc:postgresql://host:5432/synapse \
  -e SPRING_DATASOURCE_USERNAME=postgres -e SPRING_DATASOURCE_PASSWORD=password \
  -e JWT_SECRET=some-secret -p 8080:8080 synapse-backend:latest
```

Docker Compose
--------------
A `docker-compose.yml` is included to run the backend together with a PostgreSQL database for local development.

Build and run with Docker Compose:

```bash
cd back-end
# Compose will build the backend image (uses the Dockerfile multi-stage build)
docker-compose up --build
```

The backend will be available at http://localhost:8080 and will connect to the Postgres service at `db:5432` inside the compose network.

Stop and remove containers and volumes:

```bash
cd back-end
docker-compose down -v
```

Environment variables
---------------------
You can override DB and JWT settings by passing environment variables to the `backend` service in the `docker-compose.yml` or by providing an `.env` file in the `back-end` directory with keys like:

```
SPRING_DATASOURCE_URL=jdbc:postgresql://db:5432/synapse
SPRING_DATASOURCE_USERNAME=synapse
SPRING_DATASOURCE_PASSWORD=synapse
JWT_SECRET=change-me-to-a-long-random-secret
```

Notes
-----
- The multi-stage `Dockerfile` builds the jar inside the image which makes `docker-compose build` self-contained.
- For faster iterative development you can `mvn -DskipTests package` locally and use a simplified run that mounts the jar into the container; if you want that, I can add a dev-specific compose file.

Deployment guidance
------------------
- For AWS Elastic Beanstalk: create a single JAR-based application (use the packaged jar), set environment variables in EB console.
- For Render/GCP App Engine: build a Docker image and deploy. Use managed DB and set environment variables.

Next steps / improvements
------------------------
- Implement refresh token endpoints and rotate/revoke logic.
- Add transactional tests for repository behavior.
- Harden security: rate-limiting, login throttling, account confirmation, email verification.
- Add migrations (Flyway/Liquibase) to manage schema and avoid FK issues across environments.

Contact / support
-----------------
If you want me to continue and finish any missing pieces (refresh token flows, full OpenAPI annotations, more tests, or Flyway migrations), tell me which one to prioritize and I'll proceed.
