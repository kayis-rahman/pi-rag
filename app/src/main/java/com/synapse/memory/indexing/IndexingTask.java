package com.synapse.memory.indexing;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * Data Transfer Object for indexing tasks queued to Redis Streams.
 * Serialized to JSON for storage in Redis and processing by batch jobs.
 */
@Data
@AllArgsConstructor
@NoArgsConstructor
public class IndexingTask {
    private String taskType;        // "index-codebase", "index-episode", etc.
    private String targetPath;      // Path to file, directory, or resource
    private Map<String, String> metadata;  // Source type, source ID, etc.
    private LocalDateTime createdAt;
    private int retryCount;

    /**
     * Create a new indexing task with default values.
     */
    public static IndexingTask createIndexingCodebase(String codebasePath) {
        IndexingTask task = new IndexingTask();
        task.setTaskType("index-codebase");
        task.setTargetPath(codebasePath);
        task.setCreatedAt(LocalDateTime.now());
        task.setRetryCount(0);
        task.setMetadata(new HashMap<>());
        return task;
    }

    /**
     * Create a new indexing task for episodes.
     */
    public static IndexingTask createIndexingEpisode(String sessionId, String episodeId) {
        IndexingTask task = new IndexingTask();
        task.setTaskType("index-episode");
        task.setTargetPath(sessionId);
        task.setCreatedAt(LocalDateTime.now());
        task.setRetryCount(0);
        Map<String, String> metadata = new HashMap<>();
        metadata.put("sessionId", sessionId);
        metadata.put("episodeId", episodeId);
        task.setMetadata(metadata);
        return task;
    }
}
