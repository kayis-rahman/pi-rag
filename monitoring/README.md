# Synapse Monitoring Stack

This directory contains Prometheus and Grafana configuration for monitoring the Synapse LLM routing system.

## Components

- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **Synapse Application**: The monitored Spring Boot application

## Quick Start

### Option 1: Using Docker Compose

```bash
# Start the monitoring stack
docker-compose -f docker-compose.monitoring.yml up -d

# Check status
docker-compose -f docker-compose.monitoring.yml ps
```

### Option 2: Manual Setup

#### 1. Start Prometheus

```bash
docker run -d \
  --name prometheus \
  -p 9090:9090 \
  -v $(pwd)/monitoring/prometheus.yml:/etc/prometheus/prometheus.yml:ro \
  -v prometheus_data:/prometheus \
  prom/prometheus:v2.52.0
```

#### 2. Start Grafana

```bash
docker run -d \
  --name grafana \
  -p 3000:3000 \
  -e GF_SECURITY_ADMIN_USER=admin \
  -e GF_SECURITY_ADMIN_PASSWORD=admin \
  -v $(pwd)/monitoring/grafana/provisioning:/etc/grafana/provisioning:ro \
  -v grafana_data:/var/lib/grafana \
  grafana/grafana:11.1.0
```

#### 3. Run Synapse Application

```bash
# In a separate terminal
./gradlew bootRun
```

## Access Points

- **Prometheus UI**: http://localhost:9090
- **Grafana UI**: http://localhost:3000 (admin/admin)
- **Synapse Metrics Endpoint**: http://localhost:8080/actuator/prometheus

## Available Metrics

### API Metrics
- `synapse_api_calls_total` - Total API calls by endpoint and method
- `synapse_api_response_time` - API response time histograms

### Model Metrics
- `synapse_model_calls_total` - Total calls to each LLM model
- `synapse_model_response_time` - Model response time histograms
- `synapse_model_tokens` - Token usage (input/output)

### Routing Metrics
- `synapse_routing_decisions_total` - Routing decisions by reason and target model

### Circuit Breaker Metrics
- `synapse_circuit_breaker_calls_total` - Circuit breaker success/failure counts
- `synapse_circuit_breaker_state` - Circuit breaker state changes

## Dashboards

### Synapse LLM Monitoring Dashboard

Pre-configured Grafana dashboard with panels for:
- API request rate
- API response time (p50, p95, p99)
- Model call rate by model
- Model response time
- Routing decisions by reason
- Token usage rate
- Circuit breaker status

Import the dashboard JSON: `monitoring/grafana/provisioning/dashboards/synapse-dashboard.json`

## Custom Metrics

To add custom metrics to your code:

```java
@Autowired
private MetricsService metricsService;

// Record API call
metricsService.recordApiCall("/endpoint", "GET");

// Record model call
metricsService.recordModelCall("claude-3-5-sonnet");

// Record response time
metricsService.recordModelResponseTime("claude-3-5-sonnet", durationMs);

// Record token usage
metricsService.recordTokenUsage("claude-3-5-sonnet", inputTokens, outputTokens);

// Record routing decision
metricsService.recordRoutingDecision("code_task", "QWEN_LOCAL");
```

## Configuration

### Prometheus Scrape Configuration

Edit `monitoring/prometheus.yml` to customize:
- Scrape interval
- Target endpoints
- Alert rules

### Grafana Datasource

The Grafana datasource is auto-provisioned from `monitoring/grafana/provisioning/datasources/datasources.yml`.

### Dashboard Provisioning

Dashboards are auto-loaded from `monitoring/grafana/provisioning/dashboards/`.

## Troubleshooting

### Prometheus can't scrape Synapse

1. Check that Synapse is running: `curl http://localhost:8080/actuator/prometheus`
2. Verify Prometheus config: `docker logs prometheus`
3. Check network connectivity between containers

### Grafana can't connect to Prometheus

1. Verify Prometheus is accessible: `curl http://localhost:9090/api/v1/status/buildinfo`
2. Check Grafana logs: `docker logs grafana`
3. Ensure datasource URL is correct: `http://prometheus:9090` (internal) or `http://localhost:9090` (external)

## Cleanup

```bash
docker-compose -f docker-compose.monitoring.yml down
# To remove volumes as well:
docker-compose -f docker-compose.monitoring.yml down -v