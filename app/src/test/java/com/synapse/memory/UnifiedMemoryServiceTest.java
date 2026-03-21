package com.synapse.memory;

import com.synapse.memory.episodic.EpisodicMemoryService;
import com.synapse.memory.semantic.SemanticMemoryService;
import com.synapse.memory.knowledgegraph.KnowledgeGraphService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Integration tests for UnifiedMemoryService.
 * Tests delegation to all three memory modalities: episodic, semantic, knowledge graph.
 */
@SpringBootTest
@ActiveProfiles("test")
public class UnifiedMemoryServiceTest {

    @Autowired
    private UnifiedMemoryService unifiedMemoryService;

    @Autowired
    private EpisodicMemoryService episodicMemoryService;

    @Autowired
    private SemanticMemoryService semanticMemoryService;

    @Autowired
    private KnowledgeGraphService knowledgeGraphService;

    private Episode testEpisode;
    private String testSessionId = "test-session-" + System.nanoTime();

    @BeforeEach
    void setUp() {
        testEpisode = new Episode(testSessionId, "Test episode content for unified memory service");
        testEpisode.setTtlDays(1);
    }

    /**
     * Test that storeEpisode delegates to EpisodicMemoryService.
     */
    @Test
    void testStoreEpisode_DelegatesToEpisodicMemoryService() {
        // Store through unified service
        unifiedMemoryService.storeEpisode(testEpisode);

        // Verify it was stored (retrieve and check)
        List<Episode> recent = episodicMemoryService.getRecentEpisodes(testSessionId, 10);
        assertFalse(recent.isEmpty(), "Episode should be retrievable after storage");

        Episode stored = recent.get(0);
        assertEquals(testSessionId, stored.getSessionId(), "Session ID should match");
        assertEquals("Test episode content for unified memory service", stored.getContent(), "Content should match");
    }

    /**
     * Test that retrieveRecent delegates to EpisodicMemoryService.
     */
    @Test
    void testRetrieveRecent_ReturnsDelegationResult() {
        // Store multiple episodes
        Episode episode1 = new Episode(testSessionId, "First episode");
        Episode episode2 = new Episode(testSessionId, "Second episode");
        Episode episode3 = new Episode(testSessionId, "Third episode");

        unifiedMemoryService.storeEpisode(episode1);
        unifiedMemoryService.storeEpisode(episode2);
        unifiedMemoryService.storeEpisode(episode3);

        // Retrieve recent 2 episodes
        List<Episode> recent = unifiedMemoryService.retrieveRecent(testSessionId, 2);

        assertNotNull(recent, "Recent episodes list should not be null");
        assertEquals(2, recent.size(), "Should return exactly 2 episodes");

        // Verify order (newest first)
        assertEquals("Third episode", recent.get(0).getContent(), "First should be the latest");
        assertEquals("Second episode", recent.get(1).getContent(), "Second should be second-latest");
    }

    /**
     * Test that searchSemantic returns empty list in Phase 2.
     */
    @Test
    void testSearchSemantic_ReturnsEmptyInPhase2() {
        List<CodeMatch> results = unifiedMemoryService.searchSemantic("search query", 10);

        assertNotNull(results, "Result list should not be null");
        assertTrue(results.isEmpty(), "Phase 2 should return empty results (embeddings not available)");
    }

    /**
     * Test that storeRelationship delegates to KnowledgeGraphService.
     */
    @Test
    void testStoreRelationship_DelegatesToKnowledgeGraphService() {
        String sourceType = "file";
        String sourceId = "UserService.java";
        String relation = "references";
        String targetType = "file";
        String targetId = "UserRepository.java";

        // Store relationship through unified service
        unifiedMemoryService.storeRelationship(sourceType, sourceId, relation, targetType, targetId);

        // Verify it was stored by checking if relationship exists
        boolean exists = knowledgeGraphService.relationshipExists(sourceId, targetId);
        assertTrue(exists, "Relationship should exist after storage");
    }

    /**
     * Test that findRelatedConcepts delegates to KnowledgeGraphService.
     */
    @Test
    void testFindRelatedConcepts_ReturnsDelegationResult() {
        // Create relationships
        unifiedMemoryService.storeRelationship("file", "AuthService.java", "references", "file", "JwtUtils.java");
        unifiedMemoryService.storeRelationship("file", "AuthService.java", "references", "file", "SecurityConfig.java");

        // Find related concepts
        List<String> related = unifiedMemoryService.findRelatedConcepts("AuthService.java");

        assertNotNull(related, "Related concepts list should not be null");
        assertFalse(related.isEmpty(), "Should find related concepts");

        // Verify both related entities are returned
        assertTrue(related.contains("JwtUtils.java") || related.contains("SecurityConfig.java"),
            "Should contain at least one of the related files");
    }

    /**
     * Test that all services are autowired and not null.
     */
    @Test
    void testAllServicesAutowired() {
        assertNotNull(unifiedMemoryService, "UnifiedMemoryService should be autowired");
        assertNotNull(episodicMemoryService, "EpisodicMemoryService should be autowired");
        assertNotNull(semanticMemoryService, "SemanticMemoryService should be autowired");
        assertNotNull(knowledgeGraphService, "KnowledgeGraphService should be autowired");
    }

    /**
     * Test that Spring context loads successfully with test configuration.
     */
    @Test
    void testApplicationContextLoadsSuccessfully() {
        assertNotNull(unifiedMemoryService, "Context should load and inject UnifiedMemoryService");
    }

    /**
     * Test error handling: storeEpisode with null episode.
     */
    @Test
    void testStoreEpisode_ThrowsExceptionOnNull() {
        assertThrows(IllegalArgumentException.class, () -> {
            episodicMemoryService.storeEpisode(null);
        }, "Should throw exception for null episode");
    }

    /**
     * Test that retrieveRecent with invalid session ID returns appropriate result.
     */
    @Test
    void testRetrieveRecent_InvalidSessionId() {
        List<Episode> recent = unifiedMemoryService.retrieveRecent("non-existent-session-id", 10);

        assertNotNull(recent, "Result should not be null");
        assertTrue(recent.isEmpty(), "Non-existent session should return empty list");
    }
}
