# SYNAPSE Test Implementation Plan - Phase-wise Execution

## Executive Summary

**Objective**: Build comprehensive pytest test suite covering unit, integration, and end-to-end testing for SYNAPSE RAG system.

**Target Coverage**:
- Unit Tests: 80%+ for critical modules (memory stores, embedding, orchestrator)
- Integration Tests: Full cross-module coverage (RAG pipeline, MCP server, CLI)
- End-to-End Tests: Complete user workflows (setup → ingest → query)

**Timeline**: 4 Phases over 6-8 weeks

---

## Phase 1: Foundation & Test Infrastructure (Week 1)

### Goals
- Set up pytest configuration and test infrastructure
- Create shared fixtures and test utilities
- Establish test data and sample documents
- Set up CI/CD pipeline integration

### Deliverables

#### 1.1 Test Infrastructure Setup
**File**: `tests/conftest.py`
- Global pytest configuration
- Temporary directory management
- Test database setup/cleanup
- Mock embedding service fixture
- Sample documents and queries fixtures

**Tasks**:
- [ ] Create `conftest.py` with pytest configuration
- [ ] Implement `temp_dir()` fixture for temporary directories
- [ ] Implement `test_db_path()` fixture for test databases
- [ ] Implement `mock_embedding_service()` fixture for fast tests
- [ ] Implement `test_documents()` fixture with sample documents
- [ ] Implement `test_queries()` fixture with sample queries

**Acceptance Criteria**:
- All fixtures import successfully
- Temporary directories are created and cleaned up automatically
- Mock embeddings return consistent mock vectors (e.g., `[0.1] * 768`)

#### 1.2 Pytest Configuration
**File**: `pytest.ini`
- Test discovery configuration
- Coverage settings
- Marker definitions (unit/integration/e2e/slow/requires_model)
- Parallel test execution configuration

**Tasks**:
- [ ] Create `pytest.ini` with basic configuration
- [ ] Configure coverage to track `core/`, `synapse/`, `mcp_server/`
- [ ] Set up coverage thresholds (60% minimum, 80% for critical modules)
- [ ] Define markers: `unit`, `integration`, `e2e`, `slow`, `requires_model`

**Acceptance Criteria**:
- `pytest` discovers all test files
- `pytest --cov` generates coverage reports
- Markers can be used with `-m` flag (e.g., `pytest -m unit`)

#### 1.3 CI/CD Pipeline Integration
**File**: `.github/workflows/test.yml`
- GitHub Actions workflow for automated testing
- Test matrix for Python versions (3.9, 3.10, 3.11)
- Coverage upload to Codecov

**Tasks**:
- [ ] Create GitHub Actions workflow
- [ ] Configure test matrix for multiple Python versions
- [ ] Set up Codecov integration
- [ ] Add PR requirement: tests must pass before merge

**Acceptance Criteria**:
- Tests run automatically on push/PR
- Coverage reports are uploaded to Codecov
- Failed tests block PR merges

#### 1.4 Test Utilities
**File**: `tests/utils/__init__.py`
- Test helper functions
- Assertion helpers
- Mock data generators

**Tasks**:
- [ ] Create test utilities module
- [ ] Implement `assert_valid_uuid()` helper
- [ ] Implement `assert_valid_embedding()` helper
- [ ] Implement `create_test_fact()` helper
- [ ] Implement `create_test_episode()` helper
- [ ] Implement `create_test_document()` helper

**Acceptance Criteria**:
- All utility functions import successfully
- Helper functions are used in subsequent tests

---

## Phase 2: Unit Tests (Weeks 2-4)

### Goals
- Implement comprehensive unit tests for all core modules
- Achieve 80%+ coverage for critical modules
- Ensure all tests are fast (<1 second each)

### Deliverables

#### 2.1 Symbolic Memory Tests
**File**: `tests/unit/test_memory_store.py`
- 12 test methods for MemoryStore class
- Tests cover CRUD operations, querying, validation

**Tasks**:
- [ ] Implement `test_add_fact()` - Add single fact
- [ ] Implement `test_get_fact_by_id()` - Retrieve fact by UUID
- [ ] Implement `test_update_fact()` - Update existing fact
- [ ] Implement `test_delete_fact()` - Delete fact
- [ ] Implement `test_query_facts_by_scope()` - Filter by scope
- [ ] Implement `test_query_facts_by_category()` - Filter by category
- [ ] Implement `test_query_facts_by_confidence()` - Filter by confidence
- [ ] Implement `test_confidence_authority()` - Verify 100% authority
- [ ] Implement `test_fact_uniqueness()` - Enforce uniqueness
- [ ] Implement `test_db_persistence()` - Verify persistence
- [ ] Implement `test_invalid_fact_creation()` - Reject invalid facts
- [ ] Implement `test_timestamp_updates()` - Verify timestamp updates

**Acceptance Criteria**:
- All tests pass with `pytest tests/unit/test_memory_store.py`
- Coverage for `memory_store.py` is ≥80%

#### 2.2 Episodic Memory Tests
**File**: `tests/unit/test_episodic_store.py`
- 12 test methods for EpisodicStore class
- Tests cover CRUD operations, querying, validation

**Tasks**:
- [ ] Implement `test_add_episode()` - Add episode
- [ ] Implement `test_get_episode_by_id()` - Retrieve episode
- [ ] Implement `test_update_episode()` - Update episode
- [ ] Implement `test_delete_episode()` - Delete episode
- [ ] Implement `test_query_episodes_by_lesson_type()` - Filter by type
- [ ] Implement `test_query_episodes_by_quality()` - Filter by quality
- [ ] Implement `test_query_episodes_by_confidence()` - Filter by confidence
- [ ] Implement `test_advisory_authority()` - Verify 85% authority
- [ ] Implement `test_no_fact_assertion()` - Ensure no fact assertion
- [ ] Implement `test_lesson_extraction()` - Verify lesson extraction
- [ ] Implement `test_quality_scoring()` - Verify quality scoring
- [ ] Implement `test_db_persistence()` - Verify persistence

**Acceptance Criteria**:
- All tests pass
- Coverage for `episodic_store.py` is ≥80%

#### 2.3 Semantic Memory Tests
**File**: `tests/unit/test_semantic_store.py`
- 12 test methods for SemanticStore class
- Tests cover document storage, search, chunking

**Tasks**:
- [ ] Implement `test_add_document()` - Add document
- [ ] Implement `test_get_document_by_id()` - Retrieve document
- [ ] Implement `test_search_documents()` - Semantic search
- [ ] Implement `test_delete_document()` - Delete document
- [ ] Implement `test_chunk_splitting()` - Verify chunking
- [ ] Implement `test_metadata_storage()` - Verify metadata
- [ ] Implement `test_embedding_generation()` - Generate embeddings (mocked)
- [ ] Implement `test_non_authoritative()` - Verify 60% authority
- [ ] Implement `test_citation_tracking()` - Track citations
- [ ] Implement `test_vector_similarity()` - Verify similarity
- [ ] Implement `test_top_k_retrieval()` - Retrieve top K
- [ ] Implement `test_min_score_filter()` - Filter by score

**Acceptance Criteria**:
- All tests pass
- Coverage for `semantic_store.py` is ≥80%

#### 2.4 Embedding Service Tests
**File**: `tests/unit/test_embedding.py`
- 9 test methods for EmbeddingService class
- Tests cover embedding generation, caching, thread safety

**Tasks**:
- [ ] Implement `test_embed_single_text()` - Embed single text
- [ ] Implement `test_embed_batch()` - Embed batch
- [ ] Implement `test_embedding_cache()` - Verify caching
- [ ] Implement `test_cache_eviction()` - Verify LRU eviction
- [ ] Implement `test_test_mode()` - Verify mock embeddings
- [ ] Implement `test_embedding_dimensions()` - Verify dimensions
- [ ] Implement `test_thread_safety()` - Concurrent embedding
- [ ] Implement `test_invalid_input()` - Handle invalid input
- [ ] Implement `test_cache_key_generation()` - Verify cache keys

**Acceptance Criteria**:
- All tests pass with `SYNAPSE_TEST_MODE=true`
- Coverage for `embedding.py` is ≥80%

#### 2.5 Retrieval System Tests
**File**: `tests/unit/test_retriever.py`
- 8 test methods for Retriever class
- Tests cover search, query expansion, result formatting

**Tasks**:
- [ ] Implement `test_search_single_query()` - Single query
- [ ] Implement `test_query_expansion()` - Query expansion
- [ ] Implement `test_top_k_results()` - Retrieve K results
- [ ] Implement `test_min_score_filter()` - Filter by score
- [ ] Implement `test_result_formatting()` - Format results
- [ ] Implement `test_vector_store_integration()` - Use VectorStore
- [ ] Implement `test_embedding_service_integration()` - Use EmbeddingService
- [ ] Implement `test_empty_results()` - Handle no results

**Acceptance Criteria**:
- All tests pass
- Coverage for `retriever.py` is ≥80%

#### 2.6 RAG Orchestrator Tests
**File**: `tests/unit/test_orchestrator.py`
- 9 test methods for Orchestrator class
- Tests cover chat, streaming, context injection

**Tasks**:
- [ ] Implement `test_chat_with_context()` - Chat with RAG
- [ ] Implement `test_chat_without_context()` - Chat without RAG
- [ ] Implement `test_streaming_response()` - Streaming generation
- [ ] Implement `test_non_streaming_response()` - Non-streaming
- [ ] Implement `test_context_injection()` - Inject context
- [ ] Implement `test_llm_generation()` - Generate response (mocked)
- [ ] Implement `test_temperature_control()` - Control temperature
- [ ] Implement `test_max_tokens_control()` - Control tokens
- [ ] Implement `test_multi_model_support()` - Multi-model support

**Acceptance Criteria**:
- All tests pass
- Coverage for `orchestrator.py` is ≥80%

#### 2.7 Model Manager Tests
**File**: `tests/unit/test_model_manager.py`
- 10 test methods for ModelManager class
- Tests cover model loading, caching, external models

**Tasks**:
- [ ] Implement `test_register_model()` - Register model
- [ ] Implement `test_load_model()` - Load model
- [ ] Implement `test_unload_model()` - Unload model
- [ ] Implement `test_model_caching()` - Cache models
- [ ] Implement `test_external_model()` - External API models
- [ ] Implement `test_embedding_model()` - Load embedding model
- [ ] Implement `test_chat_model()` - Load chat model
- [ ] Implement `test_model_config_validation()` - Validate config
- [ ] Implement `test_thread_safety()` - Concurrent loading
- [ ] Implement `test_max_loaded_models()` - Respect limit

**Acceptance Criteria**:
- All tests pass
- Coverage for `model_manager.py` is ≥80%

#### 2.8 Connection Pool Tests
**File**: `tests/unit/test_connection_pool.py`
- 10 test methods for SQLiteConnectionPool class
- Tests cover pool management, thread safety

**Tasks**:
- [ ] Implement `test_pool_initialization()` - Initialize pool
- [ ] Implement `test_get_connection()` - Get connection
- [ ] Implement `test_return_connection()` - Return connection
- [ ] Implement `test_pool_exhaustion()` - Handle exhaustion
- [ ] Implement `test_lifo_ordering()` - LIFO ordering
- [ ] Implement `test_thread_safety()` - Concurrent access
- [ ] Implement `test_close_all()` - Close all connections
- [ ] Implement `test_wal_mode()` - Verify WAL mode
- [ ] Implement `test_foreign_keys_enabled()` - Verify FK constraints
- [ ] Implement `test_pool_cleanup()` - Cleanup on destruction

**Acceptance Criteria**:
- All tests pass
- Coverage for `connection_pool.py` is ≥80%

#### 2.9 Supporting Module Tests

**File**: `tests/unit/test_query_expander.py`
- [ ] Implement 6 tests for query expansion

**File**: `tests/unit/test_prompt_builder.py`
- [ ] Implement 6 tests for prompt building

**File**: `tests/unit/test_memory_reader.py`
- [ ] Implement 8 tests for memory reading

**File**: `tests/unit/test_memory_writer.py`
- [ ] Implement 7 tests for memory writing

**File**: `tests/unit/test_chunking.py`
- [ ] Implement 6 tests for text chunking

**File**: `tests/unit/test_config.py`
- [ ] Implement 8 tests for configuration

**Acceptance Criteria**:
- All unit tests pass with `pytest -m unit`
- Overall coverage for `core/` ≥70%
- Overall coverage for `synapse/` ≥60%

---

## Phase 3: Integration Tests (Weeks 5-6)

### Goals
- Implement integration tests for cross-module interactions
- Test 3-tier memory integration
- Test full RAG pipeline
- Test MCP server and CLI commands

### Deliverables

#### 3.1 Memory Integration Tests
**File**: `tests/integration/test_memory_integration.py`
- 6 test methods for 3-tier memory system integration

**Tasks**:
- [ ] Implement `test_full_memory_query()` - Query all 3 memory types
- [ ] Implement `test_authority_hierarchy()` - Respect authority
- [ ] Implement `test_memory_selector()` - Select memory type
- [ ] Implement `test_memory_conflicts()` - Resolve conflicts
- [ ] Implement `test_combined_context()` - Combine context
- [ ] Implement `test_memory_isolation()` - Memory isolation

**Acceptance Criteria**:
- All tests pass
- Verifies symbolic > episodic > semantic authority
- Tests combine data from all 3 memory types

#### 3.2 RAG Pipeline Integration Tests
**File**: `tests/integration/test_rag_pipeline.py`
- 6 test methods for end-to-end RAG pipeline

**Tasks**:
- [ ] Implement `test_ingest_retrieve_generate()` - Full pipeline
- [ ] Implement `test_document_ingestion()` - Ingest documents
- [ ] Implement `test_embedding_generation()` - Generate embeddings
- [ ] Implement `test_retrieval()` - Retrieve chunks
- [ ] Implement `test_context_injection()` - Inject context
- [ ] Implement `test_response_generation()` - Generate response
- [ ] Implement `test_rag_disable_keyword()` - Disable RAG

**Acceptance Criteria**:
- All tests pass
- Ingestion → retrieval → generation workflow verified
- Context injection verified

#### 3.3 MCP Server Integration Tests
**File**: `tests/integration/test_mcp_server.py`
- 9 test methods for MCP server tools

**Tasks**:
- [ ] Implement `test_list_projects_tool()` - List projects
- [ ] Implement `test_list_sources_tool()` - List sources
- [ ] Implement `test_get_context_tool()` - Get context
- [ ] Implement `test_search_tool()` - Search memory
- [ ] Implement `test_ingest_file_tool()` - Ingest file
- [ ] Implement `test_add_fact_tool()` - Add fact
- [ ] Implement `test_add_episode_tool()` - Add episode
- [ ] Implement `test_mcp_protocol_compliance()` - MCP compliance
- [ ] Implement `test_error_handling()` - Error handling

**Acceptance Criteria**:
- All MCP tools tested
- MCP protocol compliance verified
- Error handling verified

#### 3.4 CLI Integration Tests
**File**: `tests/integration/test_cli_integration.py`
- 11 test methods for CLI commands

**Tasks**:
- [ ] Implement `test_start_command()` - Start server
- [ ] Implement `test_stop_command()` - Stop server
- [ ] Implement `test_status_command()` - Get status
- [ ] Implement `test_ingest_command()` - Ingest file/dir
- [ ] Implement `test_query_command()` - Query knowledge base
- [ ] Implement `test_models_list_command()` - List models
- [ ] Implement `test_models_download_command()` - Download model
- [ ] Implement `test_models_remove_command()` - Remove model
- [ ] Implement `test_models_verify_command()` - Verify models
- [ ] Implement `test_setup_command()` - Run setup
- [ ] Implement `test_onboard_command()` - Run onboard

**Acceptance Criteria**:
- All CLI commands tested
- Commands execute without errors
- Output format verified

**Acceptance Criteria**:
- All integration tests pass with `pytest -m integration`
- Integration coverage for critical workflows ≥60%

---

## Phase 4: End-to-End Tests (Weeks 7-8)

### Goals
- Implement end-to-end tests for complete user workflows
- Test MCP client integration
- Performance benchmarking
- Test documentation

### Deliverables

#### 4.1 CLI Workflow Tests
**File**: `tests/e2e/test_cli_workflows.py`
- 6 test methods for complete user workflows

**Tasks**:
- [ ] Implement `test_first_time_setup()` - Fresh install
- [ ] Implement `test_model_download()` - Download models
- [ ] Implement `test_project_ingestion()` - Ingest codebase
- [ ] Implement `test_query_knowledge_base()` - Query codebase
- [ ] Implement `test_mcp_server_startup()` - Start MCP server
- [ ] Implement `test_full_workflow()` - Complete workflow

**Acceptance Criteria**:
- All tests pass
- Workflows complete without errors
- Results are correct

#### 4.2 MCP Client Integration Tests
**File**: `tests/e2e/test_mcp_integration.py`
- 4 test methods for MCP client integration

**Tasks**:
- [ ] Implement `test_mcp_client_connection()` - Connect to server
- [ ] Implement `test_mcp_tool_execution()` - Execute tools
- [ ] Implement `test_mcp_streaming()` - Handle streaming
- [ ] Implement `test_mcp_error_recovery()` - Recover from errors

**Acceptance Criteria**:
- All tests pass
- MCP client integration verified
- Error recovery verified

#### 4.3 Performance Benchmarks
**File**: `tests/benchmarks/test_performance.py`
- Performance tests for critical operations

**Tasks**:
- [ ] Implement `test_ingestion_speed()` - Measure ingestion speed
- [ ] Implement `test_query_latency()` - Measure query latency
- [ ] Implement `test_memory_usage()` - Monitor memory usage
- [ ] Implement `test_concurrent_queries()` - Test concurrent access

**Acceptance Criteria**:
- Performance baselines established
- Performance regressions detected
- Benchmark results documented

#### 4.4 Test Documentation
**File**: `tests/README.md`
- Test documentation for developers

**Tasks**:
- [ ] Write test execution guide
- [ ] Document test structure
- [ ] Document fixtures and utilities
- [ ] Provide troubleshooting guide
- [ ] Document adding new tests

**Acceptance Criteria**:
- Documentation is complete
- Developers can run tests independently
- New tests can be added easily

**Acceptance Criteria**:
- All e2e tests pass with `pytest -m e2e`
- Performance baselines documented
- Test documentation complete

---

## Testing Strategy

### Test Execution Phases

#### Local Development
```bash
# Run unit tests (fast)
pytest -m unit

# Run integration tests (slower)
pytest -m integration

# Run e2e tests (slowest)
pytest -m e2e

# Run all tests
pytest

# Run with coverage
pytest --cov=rag --cov=synapse --cov-report=html
```

#### CI/CD Pipeline
```bash
# Run all tests with SYNAPSE_TEST_MODE=true
SYNAPSE_TEST_MODE=true pytest

# Upload coverage to Codecov
codecov -t $CODECOV_TOKEN
```

### Test Data Management

#### Sample Documents
- Markdown files
- Python source files
- JSON configuration files
- Plain text files

#### Sample Queries
- Fact queries
- Code queries
- Concept queries
- Multi-hop queries

### Mocking Strategy

#### What to Mock
- Embedding models (use `SYNAPSE_TEST_MODE=true`)
- LLM generation (return mock responses)
- External APIs (use `responses` library)
- File system (use `tmp_path` fixture)

#### What NOT to Mock
- SQLite databases (use temporary databases)
- Vector stores (use in-memory implementations)
- Memory stores (use test databases)
- Configuration (use test config files)

---

## Success Metrics

### Coverage Targets
| Module | Target | Current |
|--------|--------|---------|
| `memory_store.py` | 80% | - |
| `episodic_store.py` | 80% | - |
| `semantic_store.py` | 80% | - |
| `embedding.py` | 80% | - |
| `orchestrator.py` | 80% | - |
| `retriever.py` | 70% | - |
| `model_manager.py` | 70% | - |
| `connection_pool.py` | 80% | - |
| **Overall** | **60%** | **0%** |

### Test Count Targets
| Test Type | Target | Current |
|-----------|--------|---------|
| Unit Tests | 100+ | 0 |
| Integration Tests | 30+ | 0 |
| E2E Tests | 10+ | 0 |
| **Total** | **140+** | **0** |

### Performance Targets
| Metric | Target | Current |
|--------|--------|---------|
| Unit test execution time | <60s | - |
| Full test suite execution time | <5 min | - |
| Individual test time | <1s | - |

---

## Risk Mitigation

### Potential Issues

#### 1. Slow Tests
**Risk**: Tests taking too long due to model loading
**Mitigation**:
- Use `SYNAPSE_TEST_MODE=true` for mock embeddings
- Mark slow tests with `@pytest.mark.slow`
- Skip model-dependent tests in CI unless explicitly requested

#### 2. Flaky Tests
**Risk**: Tests failing intermittently due to timing issues
**Mitigation**:
- Use pytest fixtures for proper setup/teardown
- Avoid hard-coded sleep/delay
- Use mocking for external dependencies
- Run tests multiple times to detect flakiness

#### 3. Coverage Gaps
**Risk**: Unable to achieve coverage targets
**Mitigation**:
- Focus on critical paths first
- Mark untestable code with `# pragma: no cover`
- Document why certain code is untestable
- Prioritize function-level tests over implementation details

#### 4. CI/CD Failures
**Risk**: CI tests failing due to environment differences
**Mitigation**:
- Use Docker containers for CI/CD
- Pin dependency versions
- Use `SYNAPSE_TEST_MODE=true` in CI
- Separate CI runs for different test types

---

## Dependencies

### Phase 1 Dependencies
- pytest >= 7.4.0 (already in requirements.txt)
- pytest-cov >= 4.0.0 (already in requirements.txt)
- pytest-asyncio >= 0.21.0 (already in requirements.txt)
- Python >= 3.9 (already in setup.py)

### Phase 2 Dependencies
- None (only requires Phase 1)

### Phase 3 Dependencies
- All Phase 2 unit tests passing
- All modules implemented (no placeholders)

### Phase 4 Dependencies
- All Phase 3 integration tests passing
- MCP server implemented
- CLI commands implemented

---

## Timeline Summary

| Phase | Week | Key Deliverables |
|-------|------|------------------|
| **Phase 1** | Week 1 | Test infrastructure, conftest.py, pytest.ini, CI/CD |
| **Phase 2** | Weeks 2-4 | 100+ unit tests, 70%+ coverage |
| **Phase 3** | Weeks 5-6 | 30+ integration tests, memory + RAG + MCP + CLI |
| **Phase 4** | Weeks 7-8 | 10+ e2e tests, performance benchmarks, docs |

---

## Handoff Criteria

### Phase 1 Complete
- [ ] `conftest.py` with all fixtures
- [ ] `pytest.ini` configured
- [ ] CI/CD pipeline running tests
- [ ] Test utilities implemented

### Phase 2 Complete
- [ ] All unit tests passing
- [ ] 70%+ coverage achieved
- [ ] No failing tests in CI/CD

### Phase 3 Complete
- [ ] All integration tests passing
- [ ] Cross-module integration verified
- [ ] MCP server tested
- [ ] CLI commands tested

### Phase 4 Complete
- [ ] All e2e tests passing
- [ ] Performance baselines established
- [ ] Test documentation complete
- [ ] Ready for production deployment

---

## Next Steps

### Immediate Actions (This Week)
1. Review and approve this plan
2. Set up `tests/` directory structure
3. Create `conftest.py` with basic fixtures
4. Configure `pytest.ini`
5. Set up GitHub Actions workflow

### First Milestone (End of Week 1)
- [ ] Phase 1 complete
- [ ] First unit test written and passing
- [ ] CI/CD pipeline green

---

## Contact & Support

### Questions?
- Testing infrastructure: Review `conftest.py` and `pytest.ini`
- Specific test patterns: Check existing test files
- CI/CD issues: Check `.github/workflows/test.yml`
- Coverage issues: Run `pytest --cov-report=html` and open `htmlcov/index.html`

### Resources
- [Pytest Documentation](https://docs.pytest.org/)
- [Pytest-Cov Documentation](https://pytest-cov.readthedocs.io/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---

**Last Updated**: January 4, 2026
**Version**: 1.0
**Status**: Ready for Implementation
