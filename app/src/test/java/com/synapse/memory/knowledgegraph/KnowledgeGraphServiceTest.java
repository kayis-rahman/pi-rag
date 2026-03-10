//package com.synapse.memory.knowledgegraph;
//
//import org.junit.jupiter.api.Test;
//import org.junit.jupiter.api.BeforeEach;
//import java.util.List;
//import static org.junit.jupiter.api.Assertions.*;
//
//public class KnowledgeGraphServiceTest {
//
//    private KnowledgeGraphService knowledgeGraphService;
//
//    @BeforeEach
//    void setUp() {
//        knowledgeGraphService = new KnowledgeGraphService();
//    }
//
//    @Test
//    void testStoreRelationship() {
//        knowledgeGraphService.storeRelationship("entity1", "relationship", "entity2");
//        // Method should execute without error
//        assertNotNull(knowledgeGraphService);
//    }
//
//    @Test
//    void testFindRelatedConcepts() {
//        List<String> concepts = knowledgeGraphService.findRelatedConcepts("test concept");
//        // Should return list of concepts (even if mocked)
//        assertNotNull(concepts);
//        assertTrue(concepts.size() > 0); // Mocked results should be returned
//    }
//
//    @Test
//    void testClearExpiredRelationships() {
//        knowledgeGraphService.clearExpiredRelationships();
//        // Method should execute without error
//        assertNotNull(knowledgeGraphService);
//    }
//}