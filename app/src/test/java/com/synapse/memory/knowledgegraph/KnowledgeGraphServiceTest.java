package com.synapse.memory.knowledgegraph;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.TestPropertySource;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for KnowledgeGraphService.
 * Tests relationship storage, bidirectional queries, and limit enforcement.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.NONE)
@TestPropertySource(properties = {
    "memory.knowledge.sqlite.path=:memory:"  // Use in-memory SQLite for tests
})
public class KnowledgeGraphServiceTest {

    @Autowired
    private KnowledgeGraphService knowledgeGraphService;

    @Autowired
    private JdbcTemplate knowledgeGraphJdbcTemplate;

    @BeforeEach
    public void setUp() {
        // Clear tables before each test
        knowledgeGraphJdbcTemplate.execute("DELETE FROM graph_edges");
        knowledgeGraphJdbcTemplate.execute("DELETE FROM graph_entities");
    }

    /**
     * Test 1: storeRelationship inserts edge into database
     */
    @Test
    public void testStoreRelationship_InsertsEdgeIntoDB() {
        // Act
        knowledgeGraphService.storeRelationship(
            "file", "UserService.java",
            "references",
            "file", "RepositoryInterface.java",
            null
        );

        // Assert - Verify edge exists in database
        Integer count = knowledgeGraphJdbcTemplate.queryForObject(
            "SELECT COUNT(*) FROM graph_edges WHERE source_id = ? AND target_id = ?",
            new Object[]{"UserService.java", "RepositoryInterface.java"},
            Integer.class
        );

        assertNotNull(count);
        assertEquals(1, count, "Relationship should be inserted into graph_edges");
    }

    /**
     * Test 2: findRelatedConcepts returns bidirectional connections
     */
    @Test
    public void testFindRelatedConcepts_ReturnsBidirectionalConnections() {
        // Arrange
        knowledgeGraphService.storeRelationship("file", "A", "references", "file", "B", null);
        knowledgeGraphService.storeRelationship("file", "B", "contains", "file", "C", null);
        knowledgeGraphService.storeRelationship("file", "D", "imports", "file", "A", null);

        // Act
        List<String> relatedConcepts = knowledgeGraphService.findRelatedConcepts("A", 10);

        // Assert
        assertNotNull(relatedConcepts);
        assertEquals(2, relatedConcepts.size(), "Should find 2 connected entities (B forward, D backward)");
        assertTrue(relatedConcepts.contains("B"), "Should find B (forward reference)");
        assertTrue(relatedConcepts.contains("D"), "Should find D (backward reference)");
    }

    /**
     * Test 3: queryRelationships returns specific relation type only
     */
    @Test
    public void testQueryRelationships_ReturnsSpecificRelationType() {
        // Arrange
        knowledgeGraphService.storeRelationship("file", "A", "references", "file", "B", null);
        knowledgeGraphService.storeRelationship("file", "A", "imports", "file", "C", null);
        knowledgeGraphService.storeRelationship("file", "A", "references", "file", "D", null);

        // Act
        List<String> referenceTargets = knowledgeGraphService.queryRelationships("A", "references", 10);

        // Assert
        assertNotNull(referenceTargets);
        assertEquals(2, referenceTargets.size(), "Should find exactly 2 references");
        assertTrue(referenceTargets.contains("B"), "Should include B");
        assertTrue(referenceTargets.contains("D"), "Should include D");
        assertFalse(referenceTargets.contains("C"), "Should not include C (different relation type)");
    }

    /**
     * Test 4: findRelatedConcepts respects limit parameter
     */
    @Test
    public void testFindRelatedConcepts_RespectsLimit() {
        // Arrange - Store 10 edges from the same source
        for (int i = 0; i < 10; i++) {
            knowledgeGraphService.storeRelationship(
                "file", "A",
                "references",
                "file", "Entity" + i,
                null
            );
        }

        // Act
        List<String> limited = knowledgeGraphService.findRelatedConcepts("A", 5);

        // Assert
        assertNotNull(limited);
        assertEquals(5, limited.size(), "Should respect limit parameter and return exactly 5");
    }

    /**
     * Test 5: findRelatedConcepts returns empty list for unknown entity
     */
    @Test
    public void testFindRelatedConcepts_EmptyForUnknownEntity() {
        // Act
        List<String> related = knowledgeGraphService.findRelatedConcepts("UnknownEntity", 10);

        // Assert
        assertNotNull(related);
        assertTrue(related.isEmpty(), "Should return empty list, not null");
    }

    /**
     * Test 6: storeRelationship with metadata
     */
    @Test
    public void testStoreRelationship_WithMetadata() {
        // Arrange
        Map<String, String> metadata = new HashMap<>();
        metadata.put("context", "imported from main.ts");
        metadata.put("line_number", "42");

        // Act
        knowledgeGraphService.storeRelationship(
            "file", "module.ts",
            "imports",
            "file", "utils.ts",
            metadata
        );

        // Assert - Verify metadata stored
        String storedMetadata = knowledgeGraphJdbcTemplate.queryForObject(
            "SELECT metadata FROM graph_edges WHERE source_id = ? AND target_id = ?",
            new Object[]{"module.ts", "utils.ts"},
            String.class
        );

        assertNotNull(storedMetadata, "Metadata should be stored");
        assertTrue(storedMetadata.contains("context"), "Metadata should contain context field");
    }
}