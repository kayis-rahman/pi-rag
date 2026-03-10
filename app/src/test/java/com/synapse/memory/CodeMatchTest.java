package com.synapse.memory;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.BeforeEach;
import static org.junit.jupiter.api.Assertions.*;

public class CodeMatchTest {

    private CodeMatch codeMatch;

    @BeforeEach
    void setUp() {
        codeMatch = new CodeMatch();
    }

    @Test
    void testDefaultConstructor() {
        assertNotNull(codeMatch);
        assertNull(codeMatch.getFilePath());
        assertNull(codeMatch.getContentPreview());
        assertNull(codeMatch.getSimilarityScore());
    }

    @Test
    void testParameterizedConstructor() {
        CodeMatch match = new CodeMatch("/path/to/file.java", "content preview", 0.95f);

        assertEquals("/path/to/file.java", match.getFilePath());
        assertEquals("content preview", match.getContentPreview());
        assertEquals(0.95f, match.getSimilarityScore());
    }

    @Test
    void testGettersAndSetters() {
        codeMatch.setFilePath("/path/to/updated.java");
        codeMatch.setContentPreview("updated content");
        codeMatch.setSimilarityScore(0.87f);

        assertEquals("/path/to/updated.java", codeMatch.getFilePath());
        assertEquals("updated content", codeMatch.getContentPreview());
        assertEquals(0.87f, codeMatch.getSimilarityScore());
    }
}