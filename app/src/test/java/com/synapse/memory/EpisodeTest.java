package com.synapse.memory;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.BeforeEach;
import java.time.LocalDateTime;
import static org.junit.jupiter.api.Assertions.*;

public class EpisodeTest {

    private Episode episode;

    @BeforeEach
    void setUp() {
        episode = new Episode();
    }

    @Test
    void testDefaultConstructor() {
        assertNotNull(episode.getId());
        assertNotNull(episode.getTimestamp());
        assertNull(episode.getSessionId());
        assertNull(episode.getContent());
        assertNull(episode.getTtlDays());
    }

    @Test
    void testParameterizedConstructor() {
        Episode episodeWithParams = new Episode("session123", "test content");
        assertEquals("session123", episodeWithParams.getSessionId());
        assertEquals("test content", episodeWithParams.getContent());
        assertNotNull(episodeWithParams.getId());
        assertNotNull(episodeWithParams.getTimestamp());
    }

    @Test
    void testGettersAndSetters() {
        episode.setId("test-id");
        episode.setTimestamp(LocalDateTime.now());
        episode.setSessionId("test-session");
        episode.setContent("test-content");
        episode.setTtlDays(30);

        assertEquals("test-id", episode.getId());
        assertNotNull(episode.getTimestamp());
        assertEquals("test-session", episode.getSessionId());
        assertEquals("test-content", episode.getContent());
        assertEquals(30, episode.getTtlDays());
    }
}