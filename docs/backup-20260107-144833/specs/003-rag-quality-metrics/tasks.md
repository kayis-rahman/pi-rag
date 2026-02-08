# Tasks: RAG Quality Metrics Dashboard

**Feature ID**: 003-rag-quality-metrics
**Status**: [Deferred] (Postponed - priority shifted to other features)
**Created**: January 4, 2026

---

## Phase 1: Metrics Collection Foundation (2 hours)

### 1.1 Setup & Configuration
- [x] Create `configs/metrics_config.json` configuration file
- [x] Add metrics section to main `rag_config.json`
- [ ] Define collection interval (default: 1 second)
- [ ] Define retention policy (default: 90 days)
- [ ] Configure database path (/opt/synapse/data/metrics.db)
- [ ] Add metrics port configuration (8003)

**Linked to**: Requirement FR-1, NFR-1

### 1.2 Database Schema Design
- [x] Design `metrics_raw` table schema
- [x] Design `metrics_aggregated` table schema
- [x] Design `alerts` table schema
- [x] Design `alert_history` table schema
- [ ] Define indexes for efficient querying
- [ ] Define retention policy queries
- [ ] Document schema in `docs/architecture/metrics-schema.md`

**Linked to**: Requirement DR-1, DR-2

### 1.3 MetricsCollector Class Skeleton
- [x] Create `core/metrics_collector.py` module
- [x] Implement `__init__()` with configuration loading
- [x] Implement `record_retrieval_quality()` method
- [x] Implement `record_tool_performance()` method
- [x] Implement `record_memory_usage()` method
- [x] Implement `record_auto_learning()` method
- [x] Implement `record_system_resources()` method
- [x] Add logging for debugging

**Linked to**: Requirement FR-1

### 1.4 Background Collection Thread
- [ ] Create `core/metrics_thread.py` module
- [ ] Implement `__init__()` with APScheduler setup
- [ ] Implement `start()` method
- [ ] Implement `stop()` method for graceful shutdown
- [ ] Implement `_schedule_resource_monitoring()` (every 1 second)
- [ ] Implement `_schedule_data_aggregation()` (every 1 minute)
- [ ] Implement `_schedule_data_cleanup()` (every 1 hour)
- [ ] Add `get_scheduled_jobs()` method
- [ ] Add `get_status()` method

**Linked to**: Requirement FR-1

### 1.4 Background Collection Thread
- [x] Create `core/metrics_thread.py` module
- [x] Implement `__init__()` with configuration loading
- [x] Implement `record_retrieval_quality()` method
- [x] Implement `record_tool_performance()` method
- [x] Implement `record_memory_usage()` method
- [x] Implement `record_auto_learning()` method
- [x] Implement `record_system_resources()` method
- [x] Add logging for debugging

**Linked to**: Requirement FR-1

### 4.2 MCP Tool Instrumentation
- [ ] Modify `mcp_server/rag_server.py` tool wrappers
- [ ] Add metrics recording to `list_projects()`
- [ ] Add metrics recording to `list_sources()`
- [ ] Add metrics recording to `get_context()`
- [ ] Add metrics recording to `search()`
- [ ] Add metrics recording to `ingest_file()`
- [ ] Add metrics recording to `add_fact()`
- [ ] Add metrics recording to `add_episode()`

**Linked to**: Requirement FR-1, NFR-2

### 4.3 Auto-Learning Metrics Integration
- [ ] Modify `core/auto_learning_tracker.py` to emit metrics
- [ ] Record episode creation events
- [ ] Record fact extraction events
- [ ] Record confidence scores
- [ ] Record deduplication events

**Linked to**: Requirement US-5

### 4.4 System Resource Monitoring
- [ ] Create `core/resource_monitor.py` module
- [ ] Implement CPU monitoring via psutil
- [ ] Implement memory monitoring via psutil
- [ ] Implement disk monitoring via psutil
- [ ] Implement network monitoring via psutil
- [ ] Add to MetricsCollector periodic tasks

**Linked to**: Requirement FR-1, NFR-2

---

## Phase 5: Testing (2-3 hours)

### 5.1 Unit Tests
- [ ] Create `tests/unit/core/test_metrics_collector.py`
- [ ] Test all MetricsCollector methods
- [ ] Test thread-safe operations
- [ ] Test database schema operations
- [ ] Test aggregation logic
- [ ] Test alert threshold validation

**Linked to**: Requirement NFR-5

### 5.2 Integration Tests
- [ ] Create `tests/integration/test_metrics_api.py`
- [ ] Test all API endpoints
- [ ] Test alert creation and triggering
- [ ] Test export functionality
- [ ] Test authentication middleware
- [ ] Test concurrent API calls

**Linked to**: Requirement NFR-5

### 5.3 End-to-End Tests
- [ ] Test complete metrics collection flow
- [ ] Test dashboard UI with real metrics
- [ ] Test alert triggering and notifications
- [ ] Test export functionality
- [ ] Test performance under load

**Linked to**: Requirement NFR-5

### 5.4 Performance Tests
- [ ] Measure metrics collection overhead (<5% CPU, <100MB RAM)
- [ ] Measure API response times (<100ms p95)
- [ ] Test database query performance
- [ ] Test dashboard load time (<2s)
- [ ] Test concurrent dashboard viewers (100+)

**Linked to**: Requirement NFR-1

---

## Phase 6: Deployment (1 hour)

### 6.1 Docker Configuration
- [ ] Create `docker-compose.metrics.yml`
- [ ] Create `Dockerfile.metrics`
- [ ] Configure InfluxDB service (if using InfluxDB)
- [ ] Configure metrics API service
- [ ] Configure volume mounts
- [ ] Configure networking

**Linked to**: Requirement FR-3, NFR-4

### 6.2 Documentation
- [ ] Create `docs/metrics-setup.md`
- [ ] Document configuration options
- [ ] Document dashboard usage
- [ ] Document alert configuration
- [ ] Document export functionality
- [ ] Update README.md with metrics dashboard section

**Linked to**: Requirement NFR-5

### 6.3 Deployment & Verification
- [ ] Build Docker images
- [ ] Deploy to production (Raspberry Pi 5)
- [ ] Verify metrics collection is working
- [ ] Verify dashboard is accessible
- [ ] Test real-time updates
- [ ] Verify alerts can be triggered

**Linked to**: Requirement NFR-5

---

## Status Legend

- `[ ]` - Not started
- `[x]` - Completed
- `[~]` - In progress

---

## Phase 1: Metrics Collection Foundation ✅ COMPLETE

**Status**: All Phase 1 tasks complete and committed (commit: 46b128d)
**Next**: Awaiting user approval to begin Phase 2 (Task Phase)

### Phase 1 Summary

✅ **Requirements.md Created**
- 7 user stories defined (health, retrieval quality, tool performance, memory usage, auto-learning, alerts, exports)
- 7 functional requirements defined (metrics collection, time-series DB, dashboard UI, alerts, export API)
- 5 non-functional requirements defined (performance, reliability, scalability, security, maintainability)
- Complete data schema for metrics, alerts, and aggregation

✅ **Plan.md Created**
- Full system architecture diagram
- Technology stack defined (Python, InfluxDB/SQLite, FastAPI, React/Vue)
- Component integration points documented
- Data schemas designed (metrics_raw, metrics_aggregated, alerts, alert_history)
- Performance requirements specified
- Security considerations documented
- Deployment architecture with Docker compose

✅ **Tasks.md Created (Phase 1 Only)**
- 6 phases planned (6 phases, ~8-13 hours total)
- 12 tasks for Phase 1 (all marked as `[ ]` - NOT implemented)
- Detailed subtasks for each area
- Dependencies identified (RAG system, existing components)
- Risk assessment with mitigation strategies

✅ **SDD Protocol Compliance**
- Feature directory created: `docs/specs/003-rag-quality-metrics/`
- All artifacts inside specific folder
- Central Progress Index updated with [In Progress] status
- Phase 1 complete (planning only, NO code changes)
- Awaiting user approval before proceeding to Task Phase

### Dependencies
- All new modules depend on existing RAG components
- No breaking changes to existing APIs
- Metrics collection is non-invasive (wrappers only)

### Open Questions
1. Should we use InfluxDB or SQLite for time-series database?
2. Should dashboard be React or Vue?
3. Should we expose metrics via existing MCP protocol or separate API?

---

**Last Updated**: January 4, 2026
