# ============================================================================
# Stage 1: Builder - Compile and package the Spring Boot application
# ============================================================================
FROM eclipse-temurin:21-jdk-alpine AS builder

# Create and set working directory
WORKDIR /app

# Install dumb-init for proper signal handling (needed for Alpine)
RUN apk add --no-cache dumb-init

# Copy Gradle wrapper and build files first for layer caching
COPY app/gradle ./gradle
COPY app/gradlew* app/build.gradle app/settings.gradle ./

# Download dependencies (cached layer)
RUN chmod +x ./gradlew && ./gradlew dependencies --no-daemon --refresh-dependencies

# Copy source code
COPY app/src ./src

# Build the JAR (skip tests for faster builds)
RUN ./gradlew bootJar --no-daemon -x test

# ============================================================================
# Stage 2: Runtime - Minimal JRE image with the application
# ============================================================================
FROM eclipse-temurin:21-jre-alpine AS runtime

# Install dumb-init and ca-certificates
RUN apk add --no-cache dumb-init ca-certificates

# Create non-root user for security
RUN adduser -D -u 1000 synapse

# Set working directory
WORKDIR /app

# Copy the JAR from builder stage
COPY --from=builder /app/build/libs/*.jar app.jar

# Create data directory for SQLite and set ownership
RUN mkdir -p /var/lib/synapse && chown synapse:synapse /var/lib/synapse

# Switch to non-root user
USER synapse

# Expose application port
EXPOSE 8082

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8082/actuator/health || exit 1

# Use dumb-init as entrypoint for proper signal handling
ENTRYPOINT ["dumb-init", "--", "java", "-Dspring.flyway.enabled=false", "-jar", "app.jar"]
