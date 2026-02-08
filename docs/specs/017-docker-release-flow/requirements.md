# Requirements - Docker Multi-Environment Release Flow

**Feature ID**: 017-docker-release-flow  
**Status**: In Progress  
**Last Updated**: 2026-02-08

---

## 1. Overview

### 1.1 Purpose
Establish a standardized development and release workflow using Docker with dual-environment support:
- **Development Environment (Port 8003)**: Active development with latest changes
- **Production Environment (Port 8002)**: Stable, tested release for constant use

### 1.2 Scope
- Multi-service Docker Compose configuration
- Environment-specific configurations
- Version management and release automation
- Shared memory between Mac and Pi instances

---

## 2. User Stories

### US-1: Development Environment Access
**As a** developer  
**I want** to run the latest development version on port 8003  
**So that** I can test new features and validate changes before release

**Acceptance Criteria**:
- [ ] `docker-compose up synapse-dev` starts development server on port 8003
- [ ] Uses `synapse:latest` Docker image
- [ ] Debug logging enabled for troubleshooting
- [ ] Aggressive auto-learning enabled for rapid feedback

### US-2: Production Environment Stability
**As a** user  
**I want** a stable production version on port 8002  
**So that** I have a reliable service for daily use without disruption

**Acceptance Criteria**:
- [ ] `docker-compose up synapse-prod` starts production server on port 8002
- [ ] Uses `synapse:v1.0.0` Docker image (immutable tag)
- [ ] Info level logging (less verbose)
- [ ] Moderate auto-learning (stable behavior)

### US-3: Shared Memory Across Devices
**As a** team member  
**I want** both Mac and Pi opencode instances to share the same memory  
**So that** knowledge is synchronized regardless of which device I'm using

**Acceptance Criteria**:
- [ ] Both services mount shared volume `/opt/synapse/data`
- [ ] Memory persists across container restarts
- [ ] Both services can read/write to same semantic index
- [ ] No data conflicts between dev and prod

### US-4: Clear Version Management
**As a** maintainer  
**I want** clear versioning and release notes  
**So that** I can track changes and communicate updates to users

**Acceptance Criteria**:
- [ ] `synapse:latest` always tracks main branch
- [ ] Version tags are immutable (`synapse:v1.0.0`)
- [ ] Release notes document all changes
- [ ] Scripts automate version bumping and tagging

### US-5: Easy Environment Switching
**As a** developer  
**I want** to easily switch between development and production contexts  
**So that** I can test features without disrupting my production workflow

**Acceptance Criteria**:
- [ ] `scripts/switch_env.sh` switches active environment
- [ ] Clear indication of which environment is active
- [ ] Environment-specific configurations loaded automatically
- [ ] No manual port or configuration changes needed

---

## 3. Functional Requirements

### FR-1: Docker Compose Configuration
**Requirement**: Provide multi-service Docker Compose setup

**Details**:
- Two services: `synapse-dev` and `synapse-prod`
- Shared network `synapse-net`
- Shared volume `/opt/synapse/data`
- Named volume `synapse-models` for GGUF models
- Port mapping: 8003 (dev), 8002 (prod)

**Priority**: P0 (Critical)

### FR-2: Environment-Specific Configurations
**Requirement**: Support different configurations per environment

**Details**:
- Base config: `configs/synapse.json`
- Dev overrides: `configs/synapse_dev.json`
- Prod overrides: `configs/synapse_prod.json`
- Environment variables override file configs

**Priority**: P1 (High)

### FR-3: Release Management Scripts
**Requirement**: Automate version management and releases

**Details**:
- `scripts/release.sh`: Bump version, create tag, generate notes
- `scripts/build_and_push.sh`: Build and push Docker images
- Semantic versioning (v1.0.0, v1.1.0, v2.0.0)
- Immutable release tags

**Priority**: P1 (High)

### FR-4: Environment Switching
**Requirement**: Easy switching between dev/prod contexts

**Details**:
- `scripts/switch_env.sh` with interactive or CLI args
- Environment indicator (env var or file)
- Automatic service restart on switch
- Clear status output

**Priority**: P2 (Medium)

### FR-5: Documentation
**Requirement**: Clear setup and usage documentation

**Details**:
- `release-notes.md` with version history
- Updated `README.md` with multi-env instructions
- Inline comments in Docker Compose
- Script usage documentation

**Priority**: P1 (High)

---

## 4. Non-Functional Requirements

### NFR-1: Performance
- Container startup time < 30 seconds
- Memory usage < 3GB per container (Pi 5 constraint)
- No performance degradation with shared volume

### NFR-2: Reliability
- 99.9% uptime for production environment
- Automatic restart on failure (prod only)
- Data persistence across restarts

### NFR-3: Security
- No hardcoded secrets in configuration
- Environment variables for sensitive data
- Read-only config mounts where possible

### NFR-4: Maintainability
- Follows established naming conventions
- Clear separation of concerns
- Well-documented scripts
- Version-controlled configurations

---

## 5. Constraints

### C-1: Platform Support
- Must support macOS (development)
- Must support Raspberry Pi 5 (production/deployment)
- Docker and Docker Compose required

### C-2: Resource Limits
- Pi 5 has 8GB RAM (max 3GB per container)
- 4 CPU cores (max 3 per container)
- Shared storage at `/opt/synapse/data`

### C-3: Backward Compatibility
- Existing `docker-compose.mcp.yml` must be deprecated gracefully
- Migration path documented
- No breaking changes to existing workflows

### C-4: Naming Standards
- Follow documented file naming conventions
- Snake case for scripts and configs
- Kebab case for Docker Compose files
- Lowercase with hyphens for documentation

---

## 6. Success Criteria

1. ✅ Both environments start successfully with `docker-compose up`
2. ✅ Shared memory works (data written in dev visible in prod)
3. ✅ Version management scripts work correctly
4. ✅ Environment switching is seamless
5. ✅ All acceptance criteria from user stories are met
6. ✅ Documentation is clear and complete
7. ✅ No regression in existing functionality

---

## 7. Out of Scope

- Kubernetes deployment
- Automated CI/CD pipeline
- Multi-node clustering
- Cloud deployment (AWS/GCP/Azure)
- Web UI for environment management

---

**Next Steps**: Proceed to plan.md for technical architecture
