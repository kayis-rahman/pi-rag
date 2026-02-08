# Release Notes

## v1.0.0 - 2026-02-08

### Overview

Synapse v1.0.0 introduces a standardized Docker multi-environment release flow, enabling simultaneous development and production deployments with shared memory between Mac and Raspberry Pi instances.

### New Features

#### Multi-Environment Docker Setup
- **Development Environment** (Port 8003): `synapse:latest`
  - Debug-level logging for detailed troubleshooting
  - Aggressive auto-learning mode for rapid feedback
  - Manual restart control for development workflow
  
- **Production Environment** (Port 8002): `synapse:v1.0.0`
  - Info-level logging for reduced verbosity
  - Moderate auto-learning mode for stable behavior
  - Automatic restart on failure for high availability

#### Shared Memory Architecture
- Both environments share `/opt/synapse/data` volume
- Mac and Pi opencode instances can access the same memory
- Synchronized semantic index across all devices
- Persistent storage across container restarts

#### Environment Management Scripts
- `scripts/release.sh`: Automated version management and tagging
- `scripts/switch_env.sh`: Interactive and CLI environment switching
- `scripts/build_and_push.sh`: Docker image building and registry push

#### Environment-Specific Configurations
- `configs/synapse_dev.json`: Development overrides
- `configs/synapse_prod.json`: Production overrides
- Hierarchical configuration loading (env vars → env config → base config)

### Breaking Changes

#### Docker Image Renaming
- **Old**: `rag-mcp:latest`
- **New**: `synapse:latest` (dev) and `synapse:v1.0.0` (prod)

#### Docker Compose Changes
- **Old**: `docker-compose.mcp.yml` (single service)
- **New**: `docker-compose.yml` (multi-service)

#### Service Names
- **Old**: `rag-mcp`
- **New**: `synapse-dev` and `synapse-prod`

### Migration Guide

#### Before Migration
```bash
# Backup existing data
cp -r /opt/synapse/data /opt/synapse/data.backup

# Stop existing containers
docker-compose -f docker-compose.mcp.yml down
```

#### After Migration
```bash
# Pull latest images
docker-compose pull

# Start both environments
docker-compose up -d

# Or start specific environment
docker-compose up -d synapse-dev    # Development only
docker-compose up -d synapse-prod   # Production only

# Switch environments interactively
./scripts/switch_env.sh
```

### Configuration Changes

#### Environment Variables
New environment-specific variables:
- `SYNAPSE_ENV`: Environment identifier (dev/prod)
- `SYNAPSE_CONFIG_PATH`: Path to environment config

#### Config Files
- Base: `configs/synapse.json`
- Development: `configs/synapse_dev.json`
- Production: `configs/synapse_prod.json`

### Resource Requirements

#### Per Container
- CPU: 3.0 cores (limit), 0.5 cores (reservation)
- Memory: 3GB (limit), 512MB (reservation)
- Storage: Shared `/opt/synapse/data` volume

#### Network
- Custom bridge network: `synapse-net` (172.22.0.0/16)
- Ports: 8002 (production), 8003 (development)

### Known Issues

1. **Port Conflicts**: Ensure ports 8002 and 8003 are available before starting
2. **Data Migration**: Existing data in `/opt/synapse/data` is preserved but verify compatibility
3. **Image Cache**: First build may take several minutes due to dependency installation

### Security Considerations

- No hardcoded secrets in configuration files
- Environment variables for sensitive data
- Read-only config mounts where possible
- User-only permissions on data directory (700)

### Compatibility

- **macOS**: Fully supported (development)
- **Raspberry Pi 5**: Fully supported (production/deployment)
- **Docker**: 20.10+ required
- **Docker Compose**: 1.29+ required

### Documentation

- SDD Documentation: `docs/specs/017-docker-release-flow/`
- Requirements: `docs/specs/017-docker-release-flow/requirements.md`
- Technical Plan: `docs/specs/017-docker-release-flow/plan.md`
- Task Checklist: `docs/specs/017-docker-release-flow/tasks.md`

### Files Added

```
docker-compose.yml              # Multi-service orchestration
configs/synapse_dev.json        # Development configuration
configs/synapse_prod.json       # Production configuration
scripts/release.sh              # Release management
scripts/switch_env.sh           # Environment switching
scripts/build_and_push.sh       # Docker image management
release-notes.md                # This file
```

### Files Modified

- `docs/specs/index.md`: Added feature entry

### Files Deprecated

- `docker-compose.mcp.yml`: Moved to `docs/examples/docker-compose.mcp.yml.deprecated`

### Future Work

- [ ] Kubernetes deployment manifests
- [ ] Automated CI/CD pipeline
- [ ] Health check dashboard
- [ ] Multi-node clustering support

### Support

For issues or questions:
1. Check SDD documentation in `docs/specs/017-docker-release-flow/`
2. Review migration guide above
3. Run `./scripts/switch_env.sh --help` for usage

---

**Commit**: TBD (upon release)  
**Docker Images**: `synapse:v1.0.0`, `synapse:latest`
