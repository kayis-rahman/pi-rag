# syntax=docker/dockerfile:1

# Build stage
FROM golang:1.22 AS builder
WORKDIR /app
COPY . .
RUN --mount=type=cache,target=/go/pkg/mod --mount=type=cache,target=/root/.cache/go-build \
    cd cmd/api && go build -o /bin/api

# Production image
FROM gcr.io/distroless/base-debian12
WORKDIR /
COPY --from=builder /bin/api /api
ENV PORT=8080
EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/api"]
