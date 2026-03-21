package com.synapse.memory.indexing;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.synapse.memory.semantic.SemanticMemoryService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import java.time.Instant;

/**
 * Async indexing service for non-blocking background work via Redis.
 * Queues indexing tasks to Redis and processes them via scheduled batch jobs.
 * Phase 2 infrastructure: framework for async work without blocking request handlers.
 */
@Service
@Slf4j
public class AsyncIndexingService {

    @Autowired(required = false)
    private RedisTemplate<String, Object> redisTemplate;

    @Autowired(required = false)
    private SemanticMemoryService semanticMemoryService;

    @Value("${memory.indexing.queue-name:memory:index:queue}")
    private String queueName;

    @Value("${memory.indexing.batch-interval:300000}")
    private long batchInterval;

    private final ObjectMapper objectMapper = new ObjectMapper();
    private volatile boolean initialized = false;

    /**
     * Initialize Redis Streams consumer group on startup.
     */
    @PostConstruct
    public void initializeConsumerGroup() {
        if (redisTemplate == null) {
            log.warn("Redis not configured; AsyncIndexingService will be inactive");
            return;
        }

        try {
            // Try to create consumer group; if it exists, this will throw an error which we catch
            redisTemplate.opsForStream().createGroup(queueName, "memory-indexer");
            log.info("Created Redis Streams consumer group on queue: {}", queueName);
        } catch (Exception e) {
            // Consumer group already exists or other error - log and continue
            log.debug("Consumer group initialization (may already exist): {}", e.getMessage());
        }

        initialized = true;
    }

    /**
     * Queue an indexing task to Redis for async processing.
     *
     * @param task the indexing task to queue
     * @return the task key
     */
    public String queueIndexingTask(IndexingTask task) {
        if (redisTemplate == null) {
            log.warn("Redis not configured; task not queued: {}", task.getTaskType());
            return null;
        }

        if (task == null) {
            throw new IllegalArgumentException("Task cannot be null");
        }

        try {
            if (task.getCreatedAt() == null) {
                task.setCreatedAt(java.time.LocalDateTime.now());
            }

            // Queue task to Redis as JSON
            // In Phase 2, we use a simple push mechanism without complex Stream API
            String taskKey = queueName + ":" + System.nanoTime();
            String taskJson = objectMapper.writeValueAsString(task);
            redisTemplate.opsForValue().set(taskKey, taskJson);

            // Push key to queue list
            redisTemplate.opsForList().rightPush(queueName + ":keys", taskKey);

            log.debug("Queued indexing task: {} with key: {}", task.getTaskType(), taskKey);
            return taskKey;

        } catch (Exception e) {
            log.error("Failed to queue indexing task", e);
            throw new RuntimeException("Failed to queue indexing task", e);
        }
    }

    /**
     * Batch indexer job: runs on schedule and processes pending indexing tasks.
     * Reads from the queue and processes tasks sequentially.
     */
    @Scheduled(fixedDelayString = "${memory.indexing.batch-interval:300000}")
    public void batchIndexer() {
        if (redisTemplate == null || !initialized) {
            log.debug("Batch indexer skipped (Redis not configured or not initialized)");
            return;
        }

        try {
            log.debug("Starting batch indexer for queue: {}", queueName);
            long startTime = Instant.now().toEpochMilli();
            int processedCount = 0;
            int failedCount = 0;

            // Process up to 10 tasks per batch
            int batchSize = 10;
            for (int i = 0; i < batchSize; i++) {
                // Pop task key from queue
                Object taskKeyObj = redisTemplate.opsForList().leftPop(queueName + ":keys");
                if (taskKeyObj == null) {
                    break;
                }

                try {
                    String taskKey = (String) taskKeyObj;
                    Object taskJsonObj = redisTemplate.opsForValue().get(taskKey);

                    if (taskJsonObj != null) {
                        String taskJson = (String) taskJsonObj;
                        IndexingTask task = objectMapper.readValue(taskJson, IndexingTask.class);
                        processIndexingTask(task);
                        processedCount++;
                    }

                    // Clean up task data
                    redisTemplate.delete(taskKey);

                } catch (Exception e) {
                    log.error("Failed to process indexing task", e);
                    failedCount++;
                }
            }

            long duration = Instant.now().toEpochMilli() - startTime;
            log.info("Batch indexer completed: {} processed, {} failed, {} ms",
                processedCount, failedCount, duration);

        } catch (Exception e) {
            log.error("Batch indexer failed", e);
        }
    }

    /**
     * Process a single indexing task based on its type.
     *
     * @param task the task to process
     */
    private void processIndexingTask(IndexingTask task) {
        if (task == null) {
            return;
        }

        log.debug("Processing task: type={}, target={}", task.getTaskType(), task.getTargetPath());

        switch (task.getTaskType()) {
            case "index-codebase":
                if (semanticMemoryService != null) {
                    semanticMemoryService.indexCodebase(task.getTargetPath());
                }
                break;

            case "index-episode":
                // Episodes are indexed synchronously in the request path
                // This case is a no-op for Phase 2
                log.debug("Episode indexing skipped (synchronous in request path)");
                break;

            default:
                log.warn("Unknown indexing task type: {}", task.getTaskType());
        }
    }
}
