package com.synapse.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

/**
 * Spring configuration for async memory operations.
 * Provides a ThreadPoolTaskExecutor bean for background indexing and async tasks.
 */
@Configuration
public class MemoryTaskExecutorConfig {

    /**
     * Create and configure a ThreadPoolTaskExecutor for memory operations.
     * Used by @Async methods and scheduled batch jobs.
     *
     * @param coreSize       the core number of threads
     * @param maxSize        the maximum number of threads
     * @param queueCapacity  the capacity of the task queue
     * @return configured ThreadPoolTaskExecutor bean
     */
    @Bean(name = "memoryTaskExecutor")
    public ThreadPoolTaskExecutor memoryTaskExecutor(
        @Value("${memory.async.thread-pool.core-size:5}") int coreSize,
        @Value("${memory.async.thread-pool.max-size:20}") int maxSize,
        @Value("${memory.async.thread-pool.queue-capacity:100}") int queueCapacity
    ) {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(coreSize);
        executor.setMaxPoolSize(maxSize);
        executor.setQueueCapacity(queueCapacity);
        executor.setThreadNamePrefix("memory-async-");
        executor.setWaitForTasksToCompleteOnShutdown(true);
        executor.setAwaitTerminationSeconds(60);
        executor.initialize();
        return executor;
    }
}
