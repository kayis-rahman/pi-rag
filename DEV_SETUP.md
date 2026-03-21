# Synapse Development Stack

Complete Docker Compose setup for local development with all required services.

## Services

- **PostgreSQL** (port 5432) - Main application database
- **Redis** (port 6379) - Episodic memory store
- **Qdrant** (port 6334) - Semantic memory/vector database
- **Synapse App** (port 8082) - Spring Boot application
- **Prometheus** (port 9090) - Metrics collection
- **Grafana** (port 3000) - Metrics visualization

## Quick Start

1. **Set up environment variables:**
   ```bash
   cp .env.example .env
   # Edit .env and add your ANTHROPIC_API_KEY
   ```

2. **Start the development stack:**
   ```bash
   docker-compose up -d
   ```

3. **Wait for services to be healthy:**
   ```bash
   # Check service status
   docker-compose ps
   
   # View logs
   docker-compose logs -f synapse
   ```

4. **Access services:**
   - Application: http://localhost:8082
   - Grafana: http://localhost:3000 (admin/admin)
   - Prometheus: http://localhost:9090

## Database Credentials

- **Host:** postgres (or localhost:5432 from host machine)
- **Database:** synapse
- **User:** synapse_user
- **Password:** synapse_password

## Commands

```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# View logs
docker-compose logs -f [service_name]

# Enter PostgreSQL
docker-compose exec postgres psql -U synapse_user -d synapse

# View service status
docker-compose ps

# Remove volumes (clean slate)
docker-compose down -v
```

## Troubleshooting

### Application won't connect to database
- Wait a few seconds for PostgreSQL to initialize
- Check logs: `docker-compose logs postgres`
- Verify health: `docker-compose ps`

### Port already in use
- Change port mappings in `docker-compose.yml`
- Or stop conflicting services: `docker ps` and `docker stop <container>`

### Database schema missing
- Flyway migrations run automatically on startup
- Check logs for migration errors: `docker-compose logs synapse`
