package com.synapse.memory.knowledgegraph;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Service for managing knowledge graph relationships using SQLite triple store.
 * Stores semantic relationships as edges (source, relation, target) with indexed queries.
 */
@Service
public class KnowledgeGraphService {

    private static final Logger logger = LoggerFactory.getLogger(KnowledgeGraphService.class);

    @Autowired
    private JdbcTemplate knowledgeGraphJdbcTemplate;

    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * Store a relationship as a triple edge (source, relation, target).
     *
     * @param sourceType   Type of source entity (e.g., "file", "concept")
     * @param sourceId     ID of source entity
     * @param relation     Relationship type (e.g., "references", "contains")
     * @param targetType   Type of target entity
     * @param targetId     ID of target entity
     * @param metadata     Optional JSON metadata for the relationship
     */
    public void storeRelationship(String sourceType, String sourceId, String relation,
                                  String targetType, String targetId, Map<String, String> metadata) {
        if (sourceId == null || sourceId.isEmpty()) {
            throw new IllegalArgumentException("Source ID cannot be null or empty");
        }
        if (relation == null || relation.isEmpty()) {
            throw new IllegalArgumentException("Relation cannot be null or empty");
        }
        if (targetId == null || targetId.isEmpty()) {
            throw new IllegalArgumentException("Target ID cannot be null or empty");
        }

        try {
            String metadataJson = null;
            if (metadata != null && !metadata.isEmpty()) {
                metadataJson = objectMapper.writeValueAsString(metadata);
            }

            String sql = """
                INSERT INTO graph_edges (source_type, source_id, relation, target_type, target_id, metadata)
                VALUES (?, ?, ?, ?, ?, ?)
                """;

            knowledgeGraphJdbcTemplate.update(sql,
                sourceType, sourceId, relation, targetType, targetId, metadataJson);

            logger.debug("Stored relationship: {} -> {} -> {}", sourceId, relation, targetId);
        } catch (Exception e) {
            logger.error("Failed to store relationship: {} -> {} -> {}", sourceId, relation, targetId, e);
            throw new RuntimeException("Failed to store relationship", e);
        }
    }

    /**
     * Find all related concepts for a given entity ID (bidirectional).
     * Returns both forward (source_id = ?) and backward (target_id = ?) connections.
     *
     * @param entityId Entity ID to query
     * @param limit    Maximum number of results to return
     * @return List of connected entity IDs
     */
    public List<String> findRelatedConcepts(String entityId, int limit) {
        if (entityId == null || entityId.isEmpty()) {
            return new ArrayList<>();
        }

        try {
            String sql = """
                SELECT DISTINCT CASE
                  WHEN source_id = ? THEN target_id
                  ELSE source_id
                END as connected_id
                FROM graph_edges
                WHERE source_id = ? OR target_id = ?
                ORDER BY created_at DESC
                LIMIT ?
                """;

            List<String> related = knowledgeGraphJdbcTemplate.query(sql,
                new Object[]{entityId, entityId, entityId, limit},
                (rs, rowNum) -> rs.getString("connected_id"));

            logger.debug("Found {} related concepts for entity: {}", related.size(), entityId);
            return related;
        } catch (Exception e) {
            logger.error("Failed to find related concepts for entity: {}", entityId, e);
            throw new RuntimeException("Failed to find related concepts", e);
        }
    }

    /**
     * Query relationships of a specific type from a source entity.
     * Returns only forward (unidirectional) connections.
     *
     * @param sourceId Source entity ID
     * @param relation Relationship type to filter
     * @param limit    Maximum number of results
     * @return List of target entity IDs matching the relation type
     */
    public List<String> queryRelationships(String sourceId, String relation, int limit) {
        if (sourceId == null || sourceId.isEmpty()) {
            return new ArrayList<>();
        }
        if (relation == null || relation.isEmpty()) {
            return new ArrayList<>();
        }

        try {
            String sql = """
                SELECT target_id FROM graph_edges
                WHERE source_id = ? AND relation = ?
                ORDER BY created_at DESC
                LIMIT ?
                """;

            List<String> targets = knowledgeGraphJdbcTemplate.query(sql,
                new Object[]{sourceId, relation, limit},
                (rs, rowNum) -> rs.getString("target_id"));

            logger.debug("Found {} targets with relation type '{}' from source: {}",
                targets.size(), relation, sourceId);
            return targets;
        } catch (Exception e) {
            logger.error("Failed to query relationships for source: {}", sourceId, e);
            throw new RuntimeException("Failed to query relationships", e);
        }
    }

    /**
     * Get all relationships for a given entity (both as source and target).
     * Returns KnowledgeGraphEdge objects with full relationship details.
     *
     * @param entity Entity ID to query
     * @return List of KnowledgeGraphEdge objects
     */
    public List<KnowledgeGraphEdge> getEntityRelationships(String entity) {
        if (entity == null || entity.isEmpty()) {
            return new ArrayList<>();
        }

        try {
            String sql = """
                SELECT source_id, relation, target_id, created_at, metadata
                FROM graph_edges
                WHERE source_id = ? OR target_id = ?
                ORDER BY created_at DESC
                """;

            List<KnowledgeGraphEdge> relationships = knowledgeGraphJdbcTemplate.query(sql,
                new Object[]{entity, entity},
                (rs, rowNum) -> {
                    KnowledgeGraphEdge edge = new KnowledgeGraphEdge();
                    edge.setSourceEntityName(rs.getString("source_id"));
                    edge.setRelationshipType(rs.getString("relation"));
                    edge.setTargetEntityName(rs.getString("target_id"));
                    return edge;
                });

            logger.debug("Retrieved {} relationships for entity: {}", relationships.size(), entity);
            return relationships;
        } catch (Exception e) {
            logger.error("Failed to retrieve relationships for entity: {}", entity, e);
            throw new RuntimeException("Failed to retrieve relationships", e);
        }
    }

    /**
     * Find all entities reachable from a starting entity through relationships.
     * Returns direct connections only (one hop).
     *
     * @param entity Entity ID to start from
     * @return List of KnowledgeGraphEdge objects
     */
    public List<KnowledgeGraphEdge> findConnectedEntities(String entity) {
        return getEntityRelationships(entity);
    }

    /**
     * Check if a relationship exists between two entities.
     *
     * @param sourceEntity Source entity ID
     * @param targetEntity Target entity ID
     * @return true if relationship exists, false otherwise
     */
    public boolean relationshipExists(String sourceEntity, String targetEntity) {
        if (sourceEntity == null || targetEntity == null) {
            return false;
        }

        try {
            String sql = "SELECT COUNT(*) FROM graph_edges WHERE source_id = ? AND target_id = ?";

            Integer count = knowledgeGraphJdbcTemplate.queryForObject(sql,
                new Object[]{sourceEntity, targetEntity},
                Integer.class);

            return count != null && count > 0;
        } catch (Exception e) {
            logger.error("Failed to check relationship existence: {} -> {}", sourceEntity, targetEntity, e);
            return false;
        }
    }

    /**
     * Clear expired relationships (placeholder - relationships don't have TTL in current schema).
     */
    public void clearExpiredRelationships() {
        logger.info("Cleared expired relationships (no TTL configured)");
    }
}