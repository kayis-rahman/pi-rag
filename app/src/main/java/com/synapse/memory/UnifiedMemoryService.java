package com.synapse.memory;

import com.synapse.memory.episodic.EpisodicMemoryService;
import com.synapse.memory.semantic.SemanticMemoryService;
import com.synapse.memory.knowledgegraph.KnowledgeGraphService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.List;

/**
 * Unified memory service facade that orchestrates all three memory modalities:
 * episodic, semantic, and knowledge graph. Provides a single interface for
 * applications to store and retrieve information across all memory types.
 */
@Service
@Slf4j
public class UnifiedMemoryService implements MemoryService {

    @Autowired
    private EpisodicMemoryService episodicMemoryService;

    @Autowired
    private SemanticMemoryService semanticMemoryService;

    @Autowired
    private KnowledgeGraphService knowledgeGraphService;

    /**
     * Store an episode in episodic memory.
     *
     * @param episode the episode to store
     */
    @Override
    public void storeEpisode(Episode episode) {
        try {
            log.debug("Storing episode for session: {}", episode.getSessionId());
            episodicMemoryService.storeEpisode(episode);
            log.debug("Episode stored successfully");
        } catch (Exception e) {
            log.error("Failed to store episode", e);
            throw e;
        }
    }

    /**
     * Retrieve recent episodes for a session.
     *
     * @param sessionId the session ID
     * @param limit     the maximum number of episodes to retrieve
     * @return list of recent episodes
     */
    @Override
    public List<Episode> retrieveRecent(String sessionId, int limit) {
        try {
            log.debug("Retrieving recent episodes for session: {}, limit: {}", sessionId, limit);
            return episodicMemoryService.getRecentEpisodes(sessionId, limit);
        } catch (Exception e) {
            log.error("Failed to retrieve recent episodes", e);
            throw e;
        }
    }

    /**
     * Search semantic memory. In Phase 2, this returns empty list (embeddings not available).
     * Phase 4 will integrate actual embedding-based search.
     *
     * @param query the query string
     * @param limit the maximum number of results
     * @return list of code matches (empty in Phase 2)
     */
    @Override
    public List<CodeMatch> searchSemantic(String query, int limit) {
        try {
            log.debug("Searching semantic memory for query: {}", query);
            return semanticMemoryService.searchSemantic(query, limit);
        } catch (Exception e) {
            log.error("Failed to search semantic memory", e);
            // Return empty list on error (semantic search is optional)
            return Collections.emptyList();
        }
    }

    /**
     * Store a relationship in the knowledge graph.
     *
     * @param sourceType the type of the source entity
     * @param sourceId   the source entity ID
     * @param relation   the relationship type
     * @param targetType the type of the target entity
     * @param targetId   the target entity ID
     */
    @Override
    public void storeRelationship(String sourceType, String sourceId, String relation, String targetType, String targetId) {
        try {
            log.debug("Storing relationship: {} -> {} -> {}", sourceId, relation, targetId);
            knowledgeGraphService.storeRelationship(sourceType, sourceId, relation, targetType, targetId, null);
            log.debug("Relationship stored successfully");
        } catch (Exception e) {
            log.error("Failed to store relationship", e);
            // Log but don't fail on non-critical knowledge graph updates
            log.warn("Knowledge graph update failed: {}", e.getMessage());
        }
    }

    /**
     * Find related concepts for an entity in the knowledge graph.
     *
     * @param entityId the entity ID to query
     * @return list of related entity IDs
     */
    @Override
    public List<String> findRelatedConcepts(String entityId) {
        try {
            log.debug("Finding related concepts for entity: {}", entityId);
            return knowledgeGraphService.findRelatedConcepts(entityId, 50);
        } catch (Exception e) {
            log.error("Failed to find related concepts", e);
            // Return empty list on error (non-critical path)
            return Collections.emptyList();
        }
    }
}