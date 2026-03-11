//package com.synapse.memory;
//
//import com.synapse.memory.episodic.EpisodicMemoryService;
//import com.synapse.memory.semantic.SemanticMemoryService;
//import com.synapse.memory.knowledgegraph.KnowledgeGraphService;
//import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.beans.factory.annotation.Value;
//import org.springframework.stereotype.Component;
//
//import jakarta.annotation.PostConstruct;
//import java.lang.management.ManagementFactory;
//import java.lang.management.MemoryMXBean;
//import java.lang.management.MemoryUsage;
//import java.util.concurrent.Executors;
//import java.util.concurrent.ScheduledExecutorService;
//import java.util.concurrent.TimeUnit;
//
//@Component
//public class MemoryManager {
//
//    @Autowired
//    private EpisodicMemoryService episodicMemoryService;
//
//    @Autowired
//    private SemanticMemoryService semanticMemoryService;
//
//    @Autowired
//    private KnowledgeGraphService knowledgeGraphService;
//
//    @Value("${memory.management.max-ram-percentage:70}")
//    private int maxRamPercentage;
//
//    @Value("${memory.management.cleanup-interval:300000}") // 5 minutes
//    private long cleanupIntervalMs;
//
//    private ScheduledExecutorService scheduler;
//    private MemoryMXBean memoryBean;
//
//    @PostConstruct
//    public void initialize() {
//        this.memoryBean = ManagementFactory.getMemoryMXBean();
//        this.scheduler = Executors.newScheduledThreadPool(1);
//
//        // Schedule periodic cleanup
//        scheduler.scheduleAtFixedRate(this::cleanupMemory,
//            cleanupIntervalMs, cleanupIntervalMs, TimeUnit.MILLISECONDS);
//    }
//
//    public void cleanupMemory() {
//        try {
//            // Check memory usage
//            MemoryUsage heapUsage = memoryBean.getHeapMemoryUsage();
//            long usedMemory = heapUsage.getUsed();
//            long maxMemory = heapUsage.getMax();
//
//            double memoryPercentage = (double) usedMemory / maxMemory * 100;
//
//            // If memory usage exceeds threshold, trigger cleanup
//            if (memoryPercentage > maxRamPercentage) {
//                System.out.println("Memory usage exceeded threshold: " +
//                    String.format("%.2f%%", memoryPercentage));
//
//                // Trigger cleanup of each memory layer
//                episodicMemoryService.clearExpiredEpisodes();
//                semanticMemoryService.clearExpiredEmbeddings();
//                knowledgeGraphService.clearExpiredRelationships();
//
//                System.out.println("Memory cleanup completed");
//            }
//        } catch (Exception e) {
//            System.err.println("Error during memory cleanup: " + e.getMessage());
//        }
//    }
//
//    public boolean isMemoryAvailable() {
//        MemoryUsage heapUsage = memoryBean.getHeapMemoryUsage();
//        long usedMemory = heapUsage.getUsed();
//        long maxMemory = heapUsage.getMax();
//
//        double memoryPercentage = (double) usedMemory / maxMemory * 1_000_000; // Per million for precision
//        return memoryPercentage < maxRamPercentage * 10_000; // Convert percentage to per million
//    }
//
//    public void shutdown() {
//        if (scheduler != null) {
//            scheduler.shutdown();
//        }
//
//        // Shutdown individual services
//        episodicMemoryService.shutdown();
//        semanticMemoryService.shutdown();
//        knowledgeGraphService.shutdown();
//    }
//}