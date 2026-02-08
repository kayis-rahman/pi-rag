# Technical Plan: RAG Quality Metrics Dashboard

**Feature ID**: 003-rag-quality-metrics
**Status**: Planning Phase
**Created**: January 4, 2026

---

## Architecture Overview

### System Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                   RAG MCP Server                      │
│  ┌────────────────────────────────────────────────────────┐  │
│  │     RAG Core (orchestrator, vectorstore, etc.)    │  │
│  └───────────┬────────────────────────────────────────┘  │
│              │                                       │
│  ┌───────────▼────────────────────────────────────────┐  │
│  │  Metrics Collection Daemon (NEW)                │  │
│  │  - Collects from all 3 memory types           │  │
│  │  - Collects tool operations                    │  │
│  │  - Collects auto-learning metrics               │  │
│  │  - Collects system resources                    │  │
│  └───────────┬────────────────────────────────────────┘  │
│              │                                       │
│  ┌───────────▼────────────────────────────────────────┐  │
│  │     Time-Series Database (NEW)                  │  │
│  │     - InfluxDB or SQLite with optimized schema     │  │
│  │     - 1-second collection interval              │  │
│  │     - 90-day retention policy                  │  │
│  └───────────┬────────────────────────────────────────┘  │
│              │                                       │
│  ┌───────────▼────────────────────────────────────────┐  │
│  │       Dashboard API (FastAPI)                    │  │
│  │     - Metrics endpoints                          │  │
│  │     - Alert management                          │  │
│  │     - Export API                                │  │
│  └───────────┬────────────────────────────────────────┘  │
└──────────────┼───────────────────────────────────────────────┘
               │
┌──────────────▼─────────────────────────────────────────────┐
│        Web Dashboard (React/Vue/Svelte)             │
│  - Health status overview                             │
│  - Retrieval quality charts                           │
│  - Tool performance metrics                            │
│  - Memory usage trends                               │
│  - Auto-learning analytics                             │
│  - Alert configuration                               │
│  - Data export                                      │
└──────────────────────────────────────────────────────────────┘
```

---

## Technology Stack

### Backend Components

**1. Metrics Collection Daemon**
- **Language**: Python 3.13+
- **Framework**: Asyncio + APScheduler for periodic tasks
- **Module**: `core/metrics_collector.py`
- **Integration**:
  - Instrument RAG operations (orchestrator, retriever, vectorstore)
  - Hook into MCP tool handlers in `mcp_server/rag_server.py`
  - Monitor auto-learning from `AutoLearningTracker`
  - System resource monitoring via `psutil`

**2. Time-Series Database**
- **Option A (Recommended)**: InfluxDB
  - Native time-series optimization
  - Efficient range queries
  - Built-in retention policies
  - ~2GB for 90 days at 1-sec interval
- **Option B (Simpler)**: SQLite with optimized schema
  - No additional dependencies
  - Simpler deployment
  - ~3GB for 90 days (less efficient)
- **Module**: `core/metrics_db.py`

**3. Dashboard API (FastAPI)**
- **Framework**: FastAPI (existing Synapse stack)
- **Port**: 8003 (next to MCP server on 8002)
- **Endpoints**:
  - `GET /api/health` - Overall system health
  - `GET /api/metrics/retrieval-quality` - Retrieval scores
  - `GET /api/metrics/tool-performance` - Tool metrics
  - `GET /api/metrics/memory-usage` - Memory storage
  - `GET /api/metrics/auto-learning` - Auto-learning stats
  - `GET /api/alerts` - Alert configuration
  - `POST /api/alerts` - Create/update alerts
  - `GET /api/export` - Export metrics (JSON/CSV)
- **Module**: `api/metrics_api.py`

**4. Web Dashboard UI**
- **Option A (Modern)**: React + Recharts
  - Component-based architecture
  - Real-time updates via WebSocket
  - Excellent chart library
  - Build step required
- **Option B (Simpler)**: Vue 3 + Chart.js
  - Single-file components
  - Reactive with good performance
  - CDN-based deployment
- **Module**: `dashboard/` (new directory)
- **Serving**: Static files served via FastAPI

---

## Data Schema

### Metrics Raw Data Schema

**Table: `metrics_raw`**
```sql
CREATE TABLE metrics_raw (
    metric_id TEXT PRIMARY KEY,
    metric_type TEXT NOT NULL,  -- "retrieval_quality", "tool_performance", etc.
    timestamp TEXT NOT NULL,    -- ISO8601 format
    value REAL NOT NULL,       -- Metric value
    tags TEXT                  -- JSON: {"memory_type": "semantic", "tool": "rag.search"}
);
```

**Indexes:**
```sql
CREATE INDEX idx_metrics_type_time ON metrics_raw(metric_type, timestamp);
CREATE INDEX idx_metrics_tags ON metrics_raw(tags);
```

### Metrics Aggregated Data Schema

**Table: `metrics_aggregated`**
```sql
CREATE TABLE metrics_aggregated (
    aggregation_id TEXT PRIMARY KEY,
    metric_type TEXT NOT NULL,
    interval TEXT NOT NULL,      -- "1m", "5m", "1h"
    timestamp TEXT NOT NULL,
    avg_value REAL,
    min_value REAL,
    max_value REAL,
    p50_value REAL,
    p95_value REAL
);
```

### Alerts Schema

**Table: `alerts`**
```sql
CREATE TABLE alerts (
    alert_id TEXT PRIMARY KEY,
    metric_type TEXT NOT NULL,
    threshold REAL NOT NULL,
    comparison TEXT NOT NULL,   -- "greater_than", "less_than"
    channels TEXT,              -- JSON: ["email", "webhook"]
    last_triggered_at TEXT,
    is_enabled BOOLEAN DEFAULT 1
);
```

### Alert History Schema

**Table: `alert_history`**
```sql
CREATE TABLE alert_history (
    history_id TEXT PRIMARY KEY,
    alert_id TEXT NOT NULL,
    triggered_at TEXT NOT NULL,
    value REAL NOT NULL,
    acknowledged_at TEXT,
    FOREIGN KEY (alert_id) REFERENCES alerts(alert_id)
);
```

---

## Component Integration

### 1. Instrumenting RAG Operations

**Orchestrator Integration** (`core/orchestrator.py`):
```python
# Wrap orchestrator methods
class MetricsInstrumentedOrchestrator:
    def __init__(self, metrics_collector):
        self.metrics = metrics_collector
        self.orchestrator = Orchestrator()

    async def orchestrate_query(self, query, options):
        start_time = time.time()
        result = await self.orchestrator.orchestrate_query(query, options)
        latency_ms = (time.time() - start_time) * 1000

        # Record retrieval quality
        self.metrics.record_retrieval_quality({
            "timestamp": datetime.now(),
            "memory_type": "semantic",
            "score": result.get("retrieval_score", 0.0),
            "query_count": len(result.get("chunks", []))
            "avg_latency_ms": latency_ms
        })

        return result
```

**MCP Tool Integration** (`mcp_server/rag_server.py`):
```python
# Wrap tool methods
async def search(self, project_id: str, query: str, ...):
    start_time = time.time()

    try:
        result = await self._search_original(...)
        latency_ms = (time.time() - start_time) * 1000

        # Record tool performance
        self.metrics_collector.record_tool_performance({
            "timestamp": datetime.now(),
            "tool_name": "rag.search",
            "operation_count": 1,
            "error_count": 0,
            "avg_latency_ms": latency_ms
        })

        return result

    except Exception as e:
        latency_ms = (time.time() - start_time) * 1000

        self.metrics_collector.record_tool_performance({
            "timestamp": datetime.now(),
            "tool_name": "rag.search",
            "operation_count": 1,
            "error_count": 1,
            "avg_latency_ms": latency_ms
        })

        raise
```

### 2. Monitoring Auto-Learning

**AutoLearningTracker Integration** (`core/auto_learning_tracker.py`):
```python
class AutoLearningTracker:
    def __init__(self, config, model_manager, metrics_collector=None):
        self.metrics_collector = metrics_collector
        # ... existing init ...

    def track_operation(self, operation):
        # ... existing logic ...

        # Record auto-learning metrics
        episodes_created = len([op for op in self.operation_buffer
                             if op.get("type") == "task_completion"])

        self.metrics_collector.record_auto_learning({
            "timestamp": datetime.now(),
            "episodes_created": episodes_created,
            "facts_extracted": self._get_fact_count(),
            "avg_confidence": self._get_avg_confidence()
        })
```

### 3. System Resource Monitoring

**Resource Collector** (`core/resource_monitor.py`):
```python
import psutil

class ResourceMonitor:
    def collect_metrics(self):
        return {
            "timestamp": datetime.now(),
            "cpu_percent": psutil.cpu_percent(interval=1),
            "memory_percent": psutil.virtual_memory().percent,
            "disk_usage_mb": psutil.disk_usage('/opt/synapse/data').used / (1024 * 1024),
            "network_bytes_sent": psutil.net_io_counters().bytes_sent,
            "network_bytes_recv": psutil.net_io_counters().bytes_recv
        }
```

---

## Performance Requirements

### Metrics Collection

- **Overhead**: <5% CPU, <100MB RAM
- **Latency**: <10ms to record metrics
- **Throughput**: 1000+ metrics/second
- **Retention**: Automatic cleanup after 90 days

### Dashboard API

- **Response time**: p95 < 100ms (aggregated), p99 < 200ms (raw range)
- **Throughput**: 100+ concurrent API calls
- **Connection pooling**: Reuse database connections

### Time-Series Database

- **Write performance**: >10,000 writes/second
- **Query performance**: <100ms for 1-hour range
- **Compression**: 60-70% space savings (time-series optimized)
- **Indexing**: Sub-100ms range queries with proper indexes

---

## Security Considerations

### Authentication

- **Dashboard API**: API key authentication (same as MCP server)
- **Web Dashboard**: Optional OAuth or JWT tokens
- **Role-based access**: Admin (all metrics) vs. Viewer (read-only)

### Data Privacy

- **Query content**: Not logged (only metadata: score, latency)
- **User data**: No PII in metrics
- **Alert payloads**: Encrypted in transit (HTTPS for webhooks)

### Rate Limiting

- **Dashboard API**: 100 requests/minute per IP
- **Export API**: 10 exports/hour per API key
- **WebSocket**: 1 connection per IP (for real-time updates)

---

## Deployment Architecture

### Docker Integration

**docker-compose.metrics.yml** (new file):
```yaml
version: '3.8'

services:
  rag-mcp:
    # ... existing MCP server config ...

  rag-metrics:
    build:
      context: .
      dockerfile: Dockerfile.metrics
    container_name: rag-metrics
    restart: unless-stopped
    ports:
      - "8003:8003"
    volumes:
      - ./data/metrics:/app/data
      - ./configs:/app/configs: read_only
    networks:
      - rag-metrics-net
    environment:
      - METRICS_DB_PATH=/app/data/metrics.db
      - RAG_MCP_URL=http://rag-mcp:8002

  influxdb:
    image: influxdb:1.8
    container_name: influxdb
    restart: unless-stopped
    ports:
      - "8086:8086"
    volumes:
      - influxdb-data:/var/lib/influxdb
    networks:
      - rag-metrics-net

volumes:
  influxdb-data:
    driver: local

networks:
  rag-metrics-net:
    driver: bridge
```

### Directory Structure

```
core/
├── metrics_collector.py       # NEW: Main metrics collection daemon
├── metrics_db.py             # NEW: Time-series database abstraction
├── resource_monitor.py        # NEW: System resource monitoring
└── auto_learning_tracker.py    # MODIFY: Add metrics_collector integration

mcp_server/
└── rag_server.py             # MODIFY: Add metrics recording to tool wrappers

api/
└── metrics_api.py            # NEW: FastAPI endpoints for dashboard

dashboard/
├── index.html                # NEW: Dashboard entry point
├── components/               # NEW: Reusable dashboard components
│   ├── HealthStatus.vue
│   ├── RetrievalChart.vue
│   ├── ToolPerformance.vue
│   ├── MemoryUsage.vue
│   ├── AutoLearning.vue
│   └── Alerts.vue
└── config.js                 # NEW: Dashboard configuration

configs/
└── metrics_config.json         # NEW: Metrics-specific configuration

docker-compose.metrics.yml       # NEW: Docker compose for metrics stack
```

---

## Dependencies

### New Python Dependencies

```toml
# pyproject.toml
[project.optional-dependencies]
metrics = [
    "influxdb-client>=1.36.0",
    "apscheduler>=3.10.0",
    "psutil>=5.9.0",
]

[project.optional-dependencies]
dashboard = [
    "fastapi[all]>=0.104.0",
    "uvicorn[standard]>=0.24.0",
]
```

### New Frontend Dependencies

```json
// package.json (if using React)
{
  "dependencies": {
    "recharts": "^2.10.0",
    "axios": "^1.6.0",
    "date-fns": "^2.30.0"
  }
}

// OR using Vue
{
  "dependencies": {
    "vue": "^3.4.0",
    "chart.js": "^4.4.0",
    "axios": "^1.6.0"
  }
}
```

---

## Implementation Phases

### Phase 1: Metrics Collection Foundation
- Create `MetricsCollector` class
- Instrument RAG operations
- Integrate with MCP tools
- Create time-series database schema
- Implement background collection thread

### Phase 2: Dashboard API
- Create FastAPI application
- Implement metrics endpoints
- Implement alert management endpoints
- Implement export endpoints
- Add authentication middleware

### Phase 3: Web Dashboard UI
- Set up React/Vue project
- Create reusable components
- Implement health overview page
- Implement retrieval quality charts
- Implement tool performance charts
- Implement memory usage charts
- Implement auto-learning analytics
- Implement alert configuration UI
- Add real-time updates (WebSocket/polling)

### Phase 4: Alerts & Exports
- Implement alert threshold logic
- Implement notification system (email/webhook)
- Implement export to JSON
- Implement export to CSV
- Add alert history tracking

### Phase 5: Testing & Deployment
- Unit tests for metrics collection
- Integration tests for API
- E2E tests for dashboard
- Performance testing
- Docker deployment
- Documentation

---

## Risk Assessment

### High Risk Items

1. **Metrics Collection Overhead**
   - **Impact**: Could slow down RAG operations
   - **Probability**: Medium
   - **Mitigation**: Async collection, monitoring overhead, configurable intervals

2. **Database Storage Growth**
   - **Impact**: Disk space exhaustion
   - **Probability**: Medium
   - **Mitigation**: Automatic cleanup, retention policies, monitoring storage usage

3. **Dashboard Performance on Pi 5**
   - **Impact**: Slow UI, poor user experience
   - **Probability**: High
   - **Mitigation**: Server-side aggregation, pagination, client-side caching

---

## Success Metrics

- **Implementation**: All phases complete in 3-4 weeks
- **Performance**: <5% overhead, <100ms API response
- **Coverage**: 90+ days of historical data
- **Uptime**: 99.9% metrics collection uptime
- **Documentation**: Complete setup and usage guides

---

**Last Updated**: January 4, 2026
