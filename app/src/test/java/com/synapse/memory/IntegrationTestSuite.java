package com.synapse.memory;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
public class IntegrationTestSuite {

    private Episode episode;
    private EmbeddingRecord embeddingRecord;
    private CodeMatch codeMatch;

    @BeforeEach
    void setUp() {
        episode = new Episode();
        embeddingRecord = new EmbeddingRecord();
        codeMatch = new CodeMatch();
    }

    @Test
    void testEpisodeLifecycle() {
        // Test episode creation and basic properties
        assertNotNull(episode.getId());
        assertNotNull(episode.getTimestamp());

        // Test setting properties
        episode.setSessionId("test-session");
        episode.setContent("test content");

        assertEquals("test-session", episode.getSessionId());
        assertEquals("test content", episode.getContent());
    }

    @Test
    void testEmbeddingRecordLifecycle() {
        // Test embedding record creation
        assertNotNull(embeddingRecord);

        // Test setting properties
        embeddingRecord.setId("test-id");
        embeddingRecord.setContent("test content");

        assertEquals("test-id", embeddingRecord.getId());
        assertEquals("test content", embeddingRecord.getContent());
    }

    @Test
    void testCodeMatchLifecycle() {
        // Test code match creation
        assertNotNull(codeMatch);

        // Test setting properties
        codeMatch.setFilePath("/path/to/file.java");
        codeMatch.setContentPreview("preview content");
        codeMatch.setSimilarityScore(0.95f);

        assertEquals("/path/to/file.java", codeMatch.getFilePath());
        assertEquals("preview content", codeMatch.getContentPreview());
        assertEquals(0.95f, codeMatch.getSimilarityScore());
    }
}