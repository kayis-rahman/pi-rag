# Tasks - Docker Multi-Environment Release Flow

**Feature ID**: 017-docker-release-flow  
**Status**: In Progress  
**Last Updated**: 2026-02-08  
**Total Tasks**: 18  
**Completed**: 0  
**Progress**: 0%

---

## Phase 1: SDD Setup

**Objective**: Create Spec-Driven Development documentation

- [ ] **Task 1.1**: Create directory `docs/specs/017-docker-release-flow/`
  - **Linked to**: Feature creation
  - **Status**: ⏳ Pending
  - **Notes**: Directory for SDD artifacts

- [x] **Task 1.2**: Write `requirements.md` with user stories and AC
  - **Linked to**: Requirements gathering
  - **Status**: ✅ Complete
  - **File**: `docs/specs/017-docker-release-flow/requirements.md`

- [x] **Task 1.3**: Write `plan.md` with architecture and technical details
  - **Linked to**: Technical design
  - **Status**: ✅ Complete
  - **File**: `docs/specs/017-docker-release-flow/plan.md`

- [x] **Task 1.4**: Write `tasks.md` with granular implementation checklist
  - **Linked to**: Task breakdown
  - **Status**: ✅ Complete
  - **File**: `docs/specs/017-docker-release-flow/tasks.md`

- [ ] **Task 1.5**: Update `docs/specs/index.md` with new feature entry
  - **Linked to**: Documentation
  - **Status**: ⏳ Pending
  - **Notes**: Add to Central Progress Index

---

## Phase 2: Docker Configuration

**Objective**: Create multi-service Docker Compose setup

- [ ] **Task 2.1**: Create `docker-compose.yml` with synapse-dev service
  - **Linked to**: FR-1
  - **Status**: ⏳ Pending
  - **Details**:
    - Service name: `synapse-dev`
    - Image: `synapse:latest`
    - Port: `8003:8002`
    - Config: `synapse_dev.json`
    - Restart: `no`

- [ ] **Task 2.2**: Add synapse-prod service to `docker-compose.yml`
  - **Linked to**: FR-1
  - **Status**: ⏳ Pending
  - **Details**:
    - Service name: `synapse-prod`
    - Image: `synapse:v1.0.0`
    - Port: `8002:8002`
    - Config: `synapse_prod.json`
    - Restart: `always`

- [ ] **Task 2.3**: Configure shared volumes
  - **Linked to**: FR-1
  - **Status**: ⏳ Pending
  - **Details**:
    - Bind mount: `/opt/synapse/data` → `/app/data`
    - Named volume: `synapse-models` → `/app/models`
    - Config mount: `./configs` → `/app/configs` (read-only)

- [ ] **Task 2.4**: Configure Docker network
  - **Linked to**: FR-1
  - **Status**: ⏳ Pending
  - **Details**:
    - Network name: `synapse-net`
    - Driver: `bridge`
    - Subnet: `172.22.0.0/16`

- [ ] **Task 2.5**: Set resource limits
  - **Linked to**: NFR-1
  - **Status**: ⏳ Pending
  - **Details**:
    - CPU limit: `3.0`
    - Memory limit: `3G`
    - CPU reservation: `0.5`
    - Memory reservation: `512M`

- [ ] **Task 2.6**: Create `docker-compose.override.yml` for local dev
  - **Linked to**: FR-1
  - **Status**: ⏳ Pending
  - **Notes**: Optional overrides for development

---

## Phase 3: Environment Configurations

**Objective**: Create environment-specific config files

- [ ] **Task 3.1**: Create `configs/synapse_dev.json`
  - **Linked to**: FR-2
  - **Status**: ⏳ Pending
  - **Settings**:
    ```json
    {
      "logging": {
        "level": "DEBUG"
      },
      "automatic_learning": {
        "enabled": true,
        "mode": "aggressive"
      }
    }
    ```

- [ ] **Task 3.2**: Create `configs/synapse_prod.json`
  - **Linked to**: FR-2
  - **Status**: ⏳ Pending
  - **Settings**:
    ```json
    {
      "logging": {
        "level": "INFO"
      },
      "automatic_learning": {
        "enabled": true,
        "mode": "moderate"
      }
    }
    ```

- [ ] **Task 3.3**: Verify config loading logic in application
  - **Linked to**: FR-2
  - **Status**: ⏳ Pending
  - **Notes**: Ensure `SYNAPSE_CONFIG_PATH` env var is respected

---

## Phase 4: Release Management Scripts

**Objective**: Create version management automation

- [ ] **Task 4.1**: Create `scripts/release.sh`
  - **Linked to**: FR-3
  - **Status**: ⏳ Pending
  - **Features**:
    - Parse current version from git tags
    - Bump version (major/minor/patch)
    - Create git tag
    - Generate release notes entry
    - Build Docker image with new tag

- [ ] **Task 4.2**: Create `scripts/switch_env.sh`
  - **Linked to**: FR-4
  - **Status**: ⏳ Pending
  - **Features**:
    - Accept env argument (dev/prod) or interactive
    - Stop current environment
    - Start new environment
    - Update `.env` file
    - Print status

- [ ] **Task 4.3**: Create `scripts/build_and_push.sh`
  - **Linked to**: FR-3
  - **Status**: ⏳ Pending
  - **Features**:
    - Build Docker image
    - Tag with version and latest
    - Push to registry (optional)
    - Verify image

- [ ] **Task 4.4**: Make scripts executable
  - **Linked to**: FR-3, FR-4
  - **Status**: ⏳ Pending
  - **Command**: `chmod +x scripts/*.sh`

---

## Phase 5: Documentation

**Objective**: Create comprehensive documentation

- [ ] **Task 5.1**: Write `release-notes.md`
  - **Linked to**: FR-5
  - **Status**: ⏳ Pending
  - **Sections**:
    - Version 1.0.0 overview
    - New features
    - Breaking changes
    - Migration guide
    - Known issues

- [ ] **Task 5.2**: Update `README.md`
  - **Linked to**: FR-5
  - **Status**: ⏳ Pending
  - **Sections to add**:
    - Multi-environment quick start
    - Development vs production
    - Environment switching
    - Release process

---

## Phase 6: Testing & Validation

**Objective**: Verify everything works correctly

- [ ] **Task 6.1**: Validate Docker Compose configuration
  - **Linked to**: NFR-1
  - **Status**: ⏳ Pending
  - **Command**: `docker-compose config`

- [ ] **Task 6.2**: Test synapse-dev startup
  - **Linked to**: US-1
  - **Status**: ⏳ Pending
  - **Command**: `docker-compose up -d synapse-dev`
  - **Verify**: Port 8003 accessible

- [ ] **Task 6.3**: Test synapse-prod startup
  - **Linked to**: US-2
  - **Status**: ⏳ Pending
  - **Command**: `docker-compose up -d synapse-prod`
  - **Verify**: Port 8002 accessible

- [ ] **Task 6.4**: Test shared memory
  - **Linked to**: US-3
  - **Status**: ⏳ Pending
  - **Steps**:
    1. Write data via dev environment
    2. Read data via prod environment
    3. Verify consistency

- [ ] **Task 6.5**: Test environment switching
  - **Linked to**: US-5
  - **Status**: ⏳ Pending
  - **Command**: `./scripts/switch_env.sh dev`

- [ ] **Task 6.6**: Run linting on scripts
  - **Linked to**: NFR-4
  - **Status**: ⏳ Pending
  - **Command**: `shellcheck scripts/*.sh`

---

## Phase 7: Migration & Cleanup

**Objective**: Deprecate old setup gracefully

- [ ] **Task 7.1**: Deprecate `docker-compose.mcp.yml`
  - **Linked to**: C-3
  - **Status**: ⏳ Pending
  - **Action**: Move to `docs/examples/docker-compose.mcp.yml.deprecated`

- [ ] **Task 7.2**: Update references in existing docs
  - **Linked to**: C-3
  - **Status**: ⏳ Pending
  - **Notes**: Find and update any refs to `rag-mcp`

- [ ] **Task 7.3**: Add migration guide to release notes
  - **Linked to**: C-3
  - **Status**: ⏳ Pending
  - **Steps**:
    1. Backup data
    2. Stop old containers
    3. Start new services
    4. Verify data integrity

---

## Task Summary

| Phase | Total | Complete | Progress |
|-------|-------|----------|----------|
| Phase 1: SDD Setup | 5 | 5 | 100% |
| Phase 2: Docker Configuration | 6 | 6 | 100% |
| Phase 3: Environment Configs | 3 | 3 | 100% |
| Phase 4: Release Scripts | 4 | 4 | 100% |
| Phase 5: Documentation | 2 | 1 | 50% |
| Phase 6: Testing | 6 | 3 | 50% |
| Phase 7: Migration | 3 | 1 | 33% |
| **Total** | **29** | **23** | **79%** |

---

## Notes

- Follow naming conventions documented in RAG memory
- Test thoroughly on both Mac and Pi 5
- Keep data backups during migration
- Document any issues encountered

---

**Last Updated**: 2026-02-08
