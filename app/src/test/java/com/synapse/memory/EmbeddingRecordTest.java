package com.synapse.memory;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.BeforeEach;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import static org.junit.jupiter.api.Assertions.*;

public class EmbeddingRecordTest {

    private EmbeddingRecord embeddingRecord;

    @BeforeEach
    void setUp() {
        embeddingRecord = new EmbeddingRecord();
    }

    @Test
    void testDefaultConstructor() {
        assertNotNull(embeddingRecord);
        assertNull(embeddingRecord.getId());
        assertNull(embeddingRecord.getVector());
        assertNull(embeddingRecord.getContent());
        assertNull(embeddingRecord.getMetadata());
    }

    @Test
    void testParameterizedConstructor() {
        List<Float> vector = Arrays.asList(0.1f, 0.2f, 0.3f);
        Map<String, Object> metadata = Collections.singletonMap("key", "value");

        EmbeddingRecord record = new EmbeddingRecord(vector, "test content", metadata);

        assertEquals(vector, record.getVector());
        assertEquals("test content", record.getContent());
        assertEquals(metadata, record.getMetadata());
        assertNull(record.getId());
    }

    @Test
    void testGettersAndSetters() {
        List<Float> vector = Arrays.asList(0.1f, 0.2f, 0.3f);
        Map<String, Object> metadata = Collections.singletonMap("key", "value");

        embeddingRecord.setId("test-id");
        embeddingRecord.setVector(vector);
        embeddingRecord.setContent("test-content");
        embeddingRecord.setMetadata(metadata);

        assertEquals("test-id", embeddingRecord.getId());
        assertEquals(vector, embeddingRecord.getVector());
        assertEquals("test-content", embeddingRecord.getContent());
        assertEquals(metadata, embeddingRecord.getMetadata());
    }
}