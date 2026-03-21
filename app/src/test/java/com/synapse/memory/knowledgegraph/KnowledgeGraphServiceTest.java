package com.synapse.memory.knowledgegraph;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;

import javax.sql.DataSource;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for KnowledgeGraphService.
 * Tests relationship storage, bidirectional queries, and limit enforcement.
 * Uses manual setup instead of @SpringBootTest to avoid PostgreSQL dependencies.
 */
public class KnowledgeGraphServiceTest {

    private KnowledgeGraphService knowledgeGraphService;
    private JdbcTemplate knowledgeGraphJdbcTemplate;

    @BeforeEach
    public void setUp() throws Exception {
        // Initialize SQLite in-memory database
        DriverManagerDataSource dataSource = new DriverManagerDataSource();
        dataSource.setDriverClassName("org.sqlite.JDBC");
        dataSource.setUrl("jdbc:sqlite::memory:");

        knowledgeGraphJdbcTemplate = new JdbcTemplate(dataSource);
        knowledgeGraphService = new KnowledgeGraphService();

        // Inject JdbcTemplate via reflection
        var field = KnowledgeGraphService.class.getDeclaredField("knowledgeGraphJdbcTemplate");
        field.setAccessible(true);
        field.set(knowledgeGraphService, knowledgeGraphJdbcTemplate);

        // Create tables if they don't exist (for in-memory SQLite)
        knowledgeGraphJdbcTemplate.execute("""
            CREATE TABLE IF NOT EXISTS graph_entities (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                entity_type TEXT NOT NULL,
                entity_id TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(entity_type, entity_id)
            )
            """);

        knowledgeGraphJdbcTemplate.execute("""
            CREATE TABLE IF NOT EXISTS graph_edges (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                source_type TEXT NOT NULL,
                source_id TEXT NOT NULL,
                relation TEXT NOT NULL,
                target_type TEXT NOT NULL,
                target_id TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                metadata TEXT
            )
            """);

        knowledgeGraphJdbcTemplate.execute("""
            CREATE INDEX IF NOT EXISTS idx_source
            ON graph_edges(source_type, source_id)
            """);

        knowledgeGraphJdbcTemplate.execute("""
            CREATE INDEX IF NOT EXISTS idx_target
            ON graph_edges(target_type, target_id)
            """);

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