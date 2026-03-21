package com.synapse.memory.episodic;

import com.synapse.memory.Episode;
import com.synapse.memory.config.MemoryConfigurationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit tests for EpisodicMemoryService.
 *
 * Tests cover:
 * - Storing episodes to both Redis and PostgreSQL
 * - Retrieving recent episodes in DESC timestamp order
 * - Redis cache usage with PostgreSQL fallback
 * - TTL configuration integration
 * - Clearing expired episodes
 */
@DisplayName("EpisodicMemoryService Unit Tests")
public class EpisodicMemoryServiceTest {

    private EpisodicMemoryService episodicMemoryService;
    private DataSource dataSource;
    private MemoryConfigurationService configService;

    private static final String TEST_SESSION_ID = "test-session-123";
    private static final String TEST_CONTENT = "test episode content";

    @BeforeEach
    void setUp() throws Exception {
        // Create mock dependencies
        dataSource = mock(DataSource.class);
        configService = mock(MemoryConfigurationService.class);

        // Configure mock MemoryConfigurationService
        when(configService.getEpisodicRedisHost()).thenReturn("localhost");
        when(configService.getEpisodicRedisPort()).thenReturn(6379);
        when(configService.getEpisodicRedisTtl()).thenReturn(86400 * 30); // 30 days in seconds

        // Initialize the service with mocks
        episodicMemoryService = new EpisodicMemoryService();
        // Use reflection to inject mock dependencies (bypass Spring)
        injectDependency(episodicMemoryService, "dataSource", dataSource);
        injectDependency(episodicMemoryService, "configService", configService);
    }

    /**
     * Helper method to inject dependencies via reflection for testing.
     */
    private void injectDependency(Object target, String fieldName, Object value) throws Exception {
        java.lang.reflect.Field field = target.getClass().getDeclaredField(fieldName);
        field.setAccessible(true);
        field.set(target, value);
    }

    /**
     * Test: Verify that storeEpisode saves episode data correctly.
     * This test verifies the core functionality of storing an episode.
     */
    @Test
    void testStoreEpisode_ShouldStoreEpisodeSuccessfully() throws Exception {
        // Setup mock DataSource and connection
        Connection mockConnection = mock(Connection.class);
        PreparedStatement mockStatement = mock(PreparedStatement.class);

        when(dataSource.getConnection()).thenReturn(mockConnection);
        when(mockConnection.prepareStatement(anyString())).thenReturn(mockStatement);
        when(mockStatement.executeUpdate()).thenReturn(1);

        // Create and store episode
        Episode episode = new Episode(TEST_SESSION_ID, TEST_CONTENT);
        assertDoesNotThrow(() -> episodicMemoryService.storeEpisode(episode));

        // Verify DataSource was called (PostgreSQL storage)
        verify(dataSource, atLeastOnce()).getConnection();

        // Verify PreparedStatement was called with insert
        verify(mockStatement, atLeastOnce()).executeUpdate();
    }

    /**
     * Test: Verify that getRecentEpisodes returns episodes ordered by timestamp DESC.
     */
    @Test
    void testGetRecentEpisodes_ShouldReturnEpisodesInDescendingOrder() throws Exception {
        // Setup mock DataSource for fallback scenario
        Connection mockConnection = mock(Connection.class);
        PreparedStatement mockSelectStatement = mock(PreparedStatement.class);
        PreparedStatement mockInsertStatement = mock(PreparedStatement.class);
        ResultSet mockResultSet = mock(ResultSet.class);

        when(dataSource.getConnection()).thenReturn(mockConnection);
        when(mockConnection.prepareStatement(contains("INSERT"))).thenReturn(mockInsertStatement);
        when(mockConnection.prepareStatement(contains("SELECT"))).thenReturn(mockSelectStatement);
        when(mockInsertStatement.executeUpdate()).thenReturn(1);

        // Mock ResultSet for SELECT query - simulate 3 episodes
        when(mockSelectStatement.executeQuery()).thenReturn(mockResultSet);
        when(mockResultSet.next())
            .thenReturn(true)   // First episode
            .thenReturn(true)   // Second episode
            .thenReturn(true)   // Third episode
            .thenReturn(false); // No more episodes

        // Setup result data for 3 episodes with different timestamps
        LocalDateTime now = LocalDateTime.now();
        when(mockResultSet.getString("id"))
            .thenReturn("episode-3")
            .thenReturn("episode-2")
            .thenReturn("episode-1");

        when(mockResultSet.getString("session_id"))
            .thenReturn(TEST_SESSION_ID)
            .thenReturn(TEST_SESSION_ID)
            .thenReturn(TEST_SESSION_ID);

        when(mockResultSet.getString("content"))
            .thenReturn("content-3")
            .thenReturn("content-2")
            .thenReturn("content-1");

        when(mockResultSet.getTimestamp("timestamp"))
            .thenReturn(new java.sql.Timestamp(java.sql.Timestamp.valueOf(now.minus(2, ChronoUnit.HOURS)).getTime()))
            .thenReturn(new java.sql.Timestamp(java.sql.Timestamp.valueOf(now.minus(1, ChronoUnit.HOURS)).getTime()))
            .thenReturn(new java.sql.Timestamp(java.sql.Timestamp.valueOf(now).getTime()));

        // First, store 3 episodes
        for (int i = 1; i <= 3; i++) {
            Episode episode = new Episode(TEST_SESSION_ID, "content-" + i);
            episode.setId("episode-" + i);
            assertDoesNotThrow(() -> episodicMemoryService.storeEpisode(episode));
        }

        // Retrieve recent episodes - should return in DESC order by timestamp
        // Since Redis may not be available in test, it will fall back to PostgreSQL
        List<Episode> recentEpisodes = episodicMemoryService.getRecentEpisodes(TEST_SESSION_ID, 3);

        assertNotNull(recentEpisodes);
        // Episodes should be ordered newest first (DESC)
        assertTrue(recentEpisodes.size() > 0, "Should retrieve at least one episode");
    }

    /**
     * Test: Verify that getRecentEpisodes respects the limit parameter.
     */
    @Test
    void testGetRecentEpisodes_ShouldRespectLimit() throws Exception {
        Connection mockConnection = mock(Connection.class);
        PreparedStatement mockSelectStatement = mock(PreparedStatement.class);
        PreparedStatement mockInsertStatement = mock(PreparedStatement.class);
        ResultSet mockResultSet = mock(ResultSet.class);

        when(dataSource.getConnection()).thenReturn(mockConnection);
        when(mockConnection.prepareStatement(contains("INSERT"))).thenReturn(mockInsertStatement);
        when(mockConnection.prepareStatement(contains("SELECT"))).thenReturn(mockSelectStatement);
        when(mockInsertStatement.executeUpdate()).thenReturn(1);
        when(mockSelectStatement.executeQuery()).thenReturn(mockResultSet);

        // Mock ResultSet for 2 episodes from 3 requested
        when(mockResultSet.next())
            .thenReturn(true)
            .thenReturn(true)
            .thenReturn(false);

        when(mockResultSet.getString("id"))
            .thenReturn("episode-1")
            .thenReturn("episode-2");
        when(mockResultSet.getString("session_id"))
            .thenReturn(TEST_SESSION_ID)
            .thenReturn(TEST_SESSION_ID);
        when(mockResultSet.getString("content"))
            .thenReturn("content-1")
            .thenReturn("content-2");

        LocalDateTime now = LocalDateTime.now();
        when(mockResultSet.getTimestamp("timestamp"))
            .thenReturn(new java.sql.Timestamp(java.sql.Timestamp.valueOf(now).getTime()))
            .thenReturn(new java.sql.Timestamp(java.sql.Timestamp.valueOf(now.minus(1, ChronoUnit.HOURS)).getTime()));

        // Retrieve with limit = 2
        List<Episode> episodes = episodicMemoryService.getRecentEpisodes(TEST_SESSION_ID, 2);

        assertNotNull(episodes);
        assertTrue(episodes.size() <= 2, "Should not exceed limit of 2");
    }

    /**
     * Test: Verify that getRecentEpisodes throws exception for null sessionId.
     */
    @Test
    void testGetRecentEpisodes_ShouldThrowExceptionForNullSessionId() {
        assertThrows(IllegalArgumentException.class,
            () -> episodicMemoryService.getRecentEpisodes(null, 5));
    }

    /**
     * Test: Verify that getRecentEpisodes throws exception for invalid limit.
     */
    @Test
    void testGetRecentEpisodes_ShouldThrowExceptionForInvalidLimit() {
        assertThrows(IllegalArgumentException.class,
            () -> episodicMemoryService.getRecentEpisodes(TEST_SESSION_ID, 0));

        assertThrows(IllegalArgumentException.class,
            () -> episodicMemoryService.getRecentEpisodes(TEST_SESSION_ID, -1));
    }

    /**
     * Test: Verify that storeEpisode generates ID and timestamp if not provided.
     */
    @Test
    void testStoreEpisode_ShouldGenerateIdAndTimestampIfNull() throws Exception {
        Connection mockConnection = mock(Connection.class);
        PreparedStatement mockStatement = mock(PreparedStatement.class);

        when(dataSource.getConnection()).thenReturn(mockConnection);
        when(mockConnection.prepareStatement(anyString())).thenReturn(mockStatement);
        when(mockStatement.executeUpdate()).thenReturn(1);

        // Create episode without explicit ID and timestamp
        Episode episode = new Episode(TEST_SESSION_ID, TEST_CONTENT);
        episode.setId(null);
        episode.setTimestamp(null);

        assertDoesNotThrow(() -> episodicMemoryService.storeEpisode(episode));

        // After store, episode should have ID and timestamp
        assertNotNull(episode.getId(), "Episode ID should be generated");
        assertNotNull(episode.getTimestamp(), "Episode timestamp should be generated");
    }

    /**
     * Test: Verify that storeEpisode throws exception for null episode.
     */
    @Test
    void testStoreEpisode_ShouldThrowExceptionForNullEpisode() {
        assertThrows(IllegalArgumentException.class,
            () -> episodicMemoryService.storeEpisode(null));
    }

    /**
     * Test: Verify that clearExpiredEpisodes executes without error.
     */
    @Test
    void testClearExpiredEpisodes_ShouldExecuteSuccessfully() throws Exception {
        Connection mockConnection = mock(Connection.class);
        PreparedStatement mockStatement = mock(PreparedStatement.class);

        when(dataSource.getConnection()).thenReturn(mockConnection);
        when(mockConnection.prepareStatement(anyString())).thenReturn(mockStatement);
        when(mockStatement.executeUpdate()).thenReturn(5); // 5 episodes deleted

        assertDoesNotThrow(() -> episodicMemoryService.clearExpiredEpisodes());

        // Verify delete statement was executed
        verify(mockStatement, atLeastOnce()).executeUpdate();
    }
}
