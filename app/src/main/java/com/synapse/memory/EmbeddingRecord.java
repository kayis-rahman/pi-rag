package com.synapse.memory;

import java.util.List;
import java.util.Map;

public class EmbeddingRecord {
    private String id;
    private List<Float> vector;
    private String content;
    private Map<String, Object> metadata;

    // Constructors
    public EmbeddingRecord() {}

    public EmbeddingRecord(List<Float> vector, String content, Map<String, Object> metadata) {
        this.vector = vector;
        this.content = content;
        this.metadata = metadata;
    }

    // Getters and setters
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public List<Float> getVector() {
        return vector;
    }

    public void setVector(List<Float> vector) {
        this.vector = vector;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public Map<String, Object> getMetadata() {
        return metadata;
    }

    public void setMetadata(Map<String, Object> metadata) {
        this.metadata = metadata;
    }
}