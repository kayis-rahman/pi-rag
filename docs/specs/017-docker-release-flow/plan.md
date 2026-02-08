# Technical Plan - Docker Multi-Environment Release Flow

**Feature ID**: 017-docker-release-flow  
**Status**: In Progress  
**Last Updated**: 2026-02-08

---

## 1. Architecture Overview

### 1.1 System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Network: synapse-net              │
│  ┌─────────────────────┐      ┌─────────────────────┐      │
│  │   synapse-dev       │      │   synapse-prod      │      │
│  │   (Development)     │      │   (Production)      │      │
│  │                     │      │                     │      │
│  │   Image: latest     │      │   Image: v1.0.0     │      │
│  │   Port: 8003        │      │   Port: 8002        │      │
│  │   Config: dev       │      │   Config: prod      │      │
│  │   Logging: DEBUG    │      │   Logging: INFO     │      │
│  │   Auto-learn:       │      │   Auto-learn:       │      │
│  │   aggressive        │      │   moderate          │      │
│  │   Restart: no       │      │   Restart: always   │      │
│  └──────────┬──────────┘      └──────────┬──────────┘      │
│             │                            │                 │
│             └────────────┬───────────────┘                 │
│                          │                                  │
│             ┌────────────▼───────────────┐                 │
│             │   Shared Resources         │                 │
│             │                            │                 │
│             │  Volume: synapse-data      │                 │
│             │  (bind: /opt/synapse/data) │                 │
│             │                            │                 │
│             │  Volume: synapse-models    │                 │
│             │  (GGUF model files)        │                 │
│             │                            │                 │
│             │  Network: synapse-net      │                 │
│             │  (172.22.0.0/16)           │                 │
│             └────────────────────────────┘                 │
└─────────────────────────────────────────────────────────────┘
         │                                    │
         │ Mount                              │ Mount
         ▼                                    ▼
┌─────────────────────┐            ┌─────────────────────┐
│   Mac (Development) │            │   Raspberry Pi 5    │
│   - Port 8003       │            │   - Port 8002       │
│   - Local dev       │            │   - Stable prod     │
│   - Test changes    │            │   - Constant use    │
└─────────────────────┘            └─────────────────────┘
```

### 1.2 Data Flow

```
Mac opencode → Port 8003 → synapse-dev → Shared Volume
                                                  ↓
Pi opencode  → Port 8002 → synapse-prod ←─────────┘
```

Both instances read/write to the same:
- Semantic index (`/opt/synapse/data/semantic_index`)
- Episodic database (`/opt/synapse/data/episodic.db`)
- Symbolic memory (`/opt/synapse/data/memory.db`)
- Metrics (`/opt/synapse/data/metrics.db`)

---

## 2. Technical Components

### 2.1 Docker Compose Configuration

**File**: `docker-compose.yml`

**Services**:

#### synapse-dev (Development)
```yaml
image: synapse:latest
container_name: synapse-dev
ports:
  - "8003:8002"
environment:
  - SYNAPSE_ENV=dev
  - SYNAPSE_CONFIG_PATH=/app/configs/synapse_dev.json
  - LOG_LEVEL=DEBUG
restart: "no"
deploy:
  resources:
    limits:
      cpus: '3.0'
      memory: 3G
```

#### synapse-prod (Production)
```yaml
image: synapse:v1.0.0
container_name: synapse-prod
ports:
  - "8002:8002"
environment:
  - SYNAPSE_ENV=prod
  - SYNAPSE_CONFIG_PATH=/app/configs/synapse_prod.json
  - LOG_LEVEL=INFO
restart: always
deploy:
  resources:
    limits:
      cpus: '3.0'
      memory: 3G
```

**Volumes**:
- `synapse-data` (bind mount): `/opt/synapse/data` → `/app/data`
- `synapse-models` (named): GGUF model files

**Network**:
- `synapse-net` (bridge, 172.22.0.0/16)

### 2.2 Configuration Hierarchy

**Priority Order** (highest to lowest):
1. Environment variables
2. Environment-specific config file (`synapse_dev.json`, `synapse_prod.json`)
3. Base config file (`synapse.json`)
4. Default values in code

**Config Loading Logic**:
```python
config_path = os.environ.get(
    "SYNAPSE_CONFIG_PATH", 
    "/app/configs/synapse.json"
)
```

### 2.3 Version Management Strategy

**Version Tags**:
- `synapse:latest` → Always points to main branch (development)
- `synapse:v1.0.0` → Immutable release tag
- `synapse:v1.1.0` → Future releases

**Release Process**:
1. Develop on `main` branch
2. Test thoroughly
3. Tag release: `git tag v1.0.0`
4. Build image: `docker build -t synapse:v1.0.0 .`
5. Push image: `docker push synapse:v1.0.0`
6. Update `release-notes.md`

### 2.4 Environment Switching

**Script**: `scripts/switch_env.sh`

**Mechanism**:
- Sets `SYNAPSE_ACTIVE_ENV` environment variable
- Creates `.env` file with active environment
- Restarts services with `docker-compose up -d`

**Usage**:
```bash
./scripts/switch_env.sh dev    # Switch to development
./scripts/switch_env.sh prod   # Switch to production
./scripts/switch_env.sh        # Interactive prompt
```

---

## 3. File Structure

```
/Users/kayisrahman/Documents/workspace/ideas/synapse/
├── docker-compose.yml              # Multi-service orchestration
├── docker-compose.override.yml     # Local development overrides
├── release-notes.md                # Version history and changes
├── Dockerfile                      # Container definition
├── README.md                       # Main documentation
├── configs/
│   ├── synapse.json               # Base configuration
│   ├── synapse_dev.json           # Development overrides
│   └── synapse_prod.json          # Production overrides
├── scripts/
│   ├── release.sh                 # Version management
│   ├── switch_env.sh              # Environment switching
│   └── build_and_push.sh          # Docker image management
└── docs/specs/017-docker-release-flow/
    ├── requirements.md            # This file
    ├── plan.md                    # Technical details
    └── tasks.md                   # Implementation checklist
```

---

## 4. Implementation Details

### 4.1 Docker Compose Implementation

**Key Decisions**:
- Use bind mount for data (shared between host and containers)
- Use named volume for models (persisted, not shared)
- Bridge network for container communication
- Resource limits for Pi 5 compatibility

**Port Mapping**:
- Host 8003 → Container 8002 (dev)
- Host 8002 → Container 8002 (prod)
- Consistent internal port simplifies configuration

### 4.2 Configuration Files

**Base Config** (`configs/synapse.json`):
- Default settings
- Shared across environments
- Main source of truth

**Dev Config** (`configs/synapse_dev.json`):
```json
{
  "logging": {
    "level": "DEBUG"
  },
  "automatic_learning": {
    "mode": "aggressive"
  }
}
```

**Prod Config** (`configs/synapse_prod.json`):
```json
{
  "logging": {
    "level": "INFO"
  },
  "automatic_learning": {
    "mode": "moderate"
  }
}
```

### 4.3 Script Implementation

**release.sh**:
- Parse current version from git tags
- Increment version (major/minor/patch)
- Create git tag
- Generate release notes entry
- Build and tag Docker image

**switch_env.sh**:
- Read current environment from `.env`
- Stop current environment
- Start new environment
- Update `.env` file
- Print status

**build_and_push.sh**:
- Build Docker image with version tag
- Tag as `latest` for dev
- Push to registry (optional)
- Verify image exists

---

## 5. Security Considerations

### 5.1 Secrets Management
- No hardcoded secrets in configs
- Use environment variables for sensitive data
- `.env` file in `.gitignore`

### 5.2 Network Security
- Internal Docker network (not exposed)
- Only ports 8002 and 8003 exposed to host
- No external network access required

### 5.3 Volume Permissions
- Data directory: User-only access (700)
- Config mounts: Read-only where possible
- Upload directory: Restricted access

---

## 6. Testing Strategy

### 6.1 Unit Testing
- Test configuration loading
- Test environment detection
- Test script logic

### 6.2 Integration Testing
- Start both environments
- Verify shared memory
- Test environment switching
- Verify port accessibility

### 6.3 Validation Checklist
- [ ] `docker-compose config` validates successfully
- [ ] Both services start without errors
- [ ] Health checks pass
- [ ] Shared volume accessible from both containers
- [ ] Port mapping correct (8002, 8003)
- [ ] Environment variables set correctly
- [ ] Config files loaded appropriately

---

## 7. Migration Plan

### 7.1 From Existing Setup

**Current State**:
- `docker-compose.mcp.yml` exists
- Single service on port 8003
- Image `rag-mcp:latest`

**Migration Steps**:
1. Stop existing containers: `docker-compose -f docker-compose.mcp.yml down`
2. Backup data: `cp -r /opt/synapse/data /opt/synapse/data.backup`
3. Rename old compose file: `mv docker-compose.mcp.yml docker-compose.mcp.yml.deprecated`
4. Create new compose file: `docker-compose.yml`
5. Pull latest images: `docker-compose pull`
6. Start new services: `docker-compose up -d`
7. Verify both services running
8. Update documentation

### 7.2 Backward Compatibility
- Keep old compose file as reference
- Document migration in release notes
- Provide rollback instructions

---

## 8. Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Data corruption with shared volume | High | Backup before migration, test thoroughly |
| Port conflicts | Medium | Verify ports available before start |
| Resource exhaustion on Pi 5 | Medium | Set memory/cpu limits, monitor usage |
| Config loading errors | Medium | Validate JSON syntax, provide defaults |
| Image tag conflicts | Low | Use immutable tags, clear naming |

---

## 9. Success Metrics

1. **Deployment Time**: < 5 minutes to start both environments
2. **Memory Usage**: < 3GB per container
3. **Uptime**: 99.9% for production environment
4. **Switch Time**: < 30 seconds to switch environments
5. **Test Coverage**: All acceptance criteria pass

---

**Next Steps**: Proceed to tasks.md for implementation checklist
