package com.synapse.memory.knowledgegraph;

/**
 * Represents a single edge (relationship) in the knowledge graph.
 * A triple edge connecting source and target entities through a relationship type.
 */
public class KnowledgeGraphEdge {

    private String id;
    private String sourceEntityId;
    private String sourceEntityName;
    private String relationshipType;
    private String targetEntityId;
    private String targetEntityName;

    public KnowledgeGraphEdge() {
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getSourceEntityId() {
        return sourceEntityId;
    }

    public void setSourceEntityId(String sourceEntityId) {
        this.sourceEntityId = sourceEntityId;
    }

    public String getSourceEntityName() {
        return sourceEntityName;
    }

    public void setSourceEntityName(String sourceEntityName) {
        this.sourceEntityName = sourceEntityName;
    }

    public String getRelationshipType() {
        return relationshipType;
    }

    public void setRelationshipType(String relationshipType) {
        this.relationshipType = relationshipType;
    }

    public String getTargetEntityId() {
        return targetEntityId;
    }

    public void setTargetEntityId(String targetEntityId) {
        this.targetEntityId = targetEntityId;
    }

    public String getTargetEntityName() {
        return targetEntityName;
    }

    public void setTargetEntityName(String targetEntityName) {
        this.targetEntityName = targetEntityName;
    }

    @Override
    public String toString() {
        return String.format("KnowledgeGraphEdge{%s -> %s -> %s}",
                sourceEntityName, relationshipType, targetEntityName);
    }
}
