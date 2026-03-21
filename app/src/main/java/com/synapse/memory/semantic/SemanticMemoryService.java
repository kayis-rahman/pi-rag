package com.synapse.memory.semantic;

import com.synapse.memory.CodeMatch;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.List;

/**
 * Semantic memory service for code similarity search and embedding indexing.
 * Phase 2 placeholder: returns empty results (embeddings available in Phase 4).
 * Phase 4 will integrate Claude embeddings API and Qdrant vector storage.
 */
@Service
@Slf4j
public class SemanticMemoryService {

    @Value("${memory.semantic.qdrant.host:localhost}")
    private String qdrantHost;

    @Value("${memory.semantic.qdrant.port:6334}")
    private int qdrantPort;

    @Value("${memory.semantic.qdrant.api-key:}")
    private String qdrantApiKey;

    /**
     * Search for semantically similar code snippets.
     * Phase 2: Returns empty list (embeddings not available).
     * Phase 4: Will generate embeddings and search Qdrant.
     *
     * @param query the query string
     * @param limit maximum number of results
     * @return list of code matches (empty in Phase 2)
     */
    public List<CodeMatch> searchSemantic(String query, int limit) {
        log.warn("searchSemantic called but embeddings not available (Phase 4 integration pending)");
        return Collections.emptyList();
    }

    /**
     * Index a codebase for semantic search.
     * Phase 2: No-op (embeddings not available).
     * Phase 4: Will read code files and generate embeddings.
     *
     * @param codebasePath the path to the codebase
     */
    public void indexCodebase(String codebasePath) {
        log.warn("indexCodebase called but embedding service not available (Phase 4 integration pending)");
        // No-op for Phase 2
    }

    /**
     * Clear expired embeddings from Qdrant.
     * Phase 2: No-op.
     */
    public void clearExpiredEmbeddings() {
        log.debug("clearExpiredEmbeddings called (no action in Phase 2)");
        // No-op for Phase 2
    }

    /**
     * Shutdown the service and release resources.
     */
    public void shutdown() {
        log.debug("SemanticMemoryService shutdown");
        // Nothing to clean up in Phase 2
    }
}