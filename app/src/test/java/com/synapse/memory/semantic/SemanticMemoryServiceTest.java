//package com.synapse.memory.semantic;
//
//import com.synapse.memory.EmbeddingRecord;
//import com.synapse.memory.CodeMatch;
//import org.junit.jupiter.api.Test;
//import org.junit.jupiter.api.BeforeEach;
//import java.util.List;
//import static org.junit.jupiter.api.Assertions.*;
//
//public class SemanticMemoryServiceTest {
//
//    private SemanticMemoryService semanticMemoryService;
//
//    @BeforeEach
//    void setUp() {
//        semanticMemoryService = new SemanticMemoryService();
//    }
//
//    @Test
//    void testIndexCodebase() {
//        semanticMemoryService.indexCodebase("/path/to/codebase");
//        // Method should execute without error
//        assertNotNull(semanticMemoryService);
//    }
//
//    @Test
//    void testSearchSimilarCode() {
//        List<CodeMatch> results = semanticMemoryService.searchSimilarCode("test query", 5);
//        // Should return list of results (even if mocked)
//        assertNotNull(results);
//        assertTrue(results.size() > 0); // Mocked results should be returned
//    }
//
//    @Test
//    void testClearExpiredEmbeddings() {
//        semanticMemoryService.clearExpiredEmbeddings();
//        // Method should execute without error
//        assertNotNull(semanticMemoryService);
//    }
//}