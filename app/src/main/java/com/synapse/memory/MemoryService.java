package com.synapse.memory;

import java.util.List;

public interface MemoryService {
    // Episodic memory operations
    void storeEpisode(Episode episode);
    List<Episode> retrieveRecent(String sessionId, int limit);

    // Semantic memory operations (Phase 4: actual embeddings)
    List<CodeMatch> searchSemantic(String query, int limit);

    // Knowledge graph operations
    void storeRelationship(String sourceType, String sourceId, String relation, String targetType, String targetId);
    List<String> findRelatedConcepts(String entityId);
}