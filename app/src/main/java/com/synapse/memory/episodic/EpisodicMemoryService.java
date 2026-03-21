package com.synapse.memory.episodic;

import com.synapse.memory.Episode;
import com.synapse.memory.config.MemoryConfigurationService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

import redis.clients.jedis.Jedis;
import redis.clients.jedis.JedisPool;
import redis.clients.jedis.JedisPoolConfig;

@Service
public class EpisodicMemoryService {

    private static final Logger logger = LoggerFactory.getLogger(EpisodicMemoryService.class);

    @Autowired
    private DataSource dataSource;

    @Autowired
    private MemoryConfigurationService configService;

    private JedisPool jedisPool;

    private static final String EPISODE_HASH_PREFIX = "episode:";
    private static final String SESSION_INDEX_ZSET = "episodes:session:";

    public EpisodicMemoryService() {
        // Empty constructor - initialization happens in @PostConstruct
    }

    @PostConstruct
    private void initializeRedisPool() {
        // Initialize Redis connection pool after dependency injection is complete
        JedisPoolConfig poolConfig = new JedisPoolConfig();
        poolConfig.setMaxTotal(20);
        poolConfig.setMaxIdle(10);
        poolConfig.setMinIdle(5);
        poolConfig.setMaxWaitMillis(30000);

        String host = configService.getEpisodicRedisHost();
        int port = configService.getEpisodicRedisPort();
        this.jedisPool = new JedisPool(poolConfig, host, port);

        logger.info("EpisodicMemoryService initialized with Redis at {}:{}", host, port);
    }

    /**
     * Store episode in both PostgreSQL (durable) and Redis (fast cache).
     * Uses HSET for episode data storage and ZSET for time-indexed retrieval.
     *
     * @param episode the episode to store
     */
    public void storeEpisode(Episode episode) {
        if (episode == null) {
            throw new IllegalArgumentException("Episode cannot be null");
        }

        String episodeId = episode.getId();
        if (episodeId == null) {
            episodeId = UUID.randomUUID().toString();
            episode.setId(episodeId);
        }

        if (episode.getTimestamp() == null) {
            episode.setTimestamp(LocalDateTime.now());
        }

        long timestamp = episode.getTimestamp().atZone(java.time.ZoneId.systemDefault()).toInstant().toEpochMilli();

        try {
            // Store in PostgreSQL (durable storage)
            storeToPostgreSQL(episodeId, episode.getSessionId(), episode.getContent(),
                    new Timestamp(System.currentTimeMillis()));

            // Store in Redis cache with TTL
            storeToRedis(episode);

        } catch (Exception e) {
            logger.error("Failed to store episode: {}", episodeId, e);
            throw new RuntimeException("Failed to store episode", e);
        }
    }

    /**
     * Retrieve recent episodes for a session.
     * Uses Redis ZSET first for fast access, falls back to PostgreSQL if cache miss.
     *
     * @param sessionId the session ID to retrieve episodes for
     * @param limit     maximum number of episodes to return
     * @return list of episodes ordered by timestamp DESC (newest first)
     */
    public List<Episode> getRecentEpisodes(String sessionId, int limit) {
        if (sessionId == null || sessionId.isEmpty()) {
            throw new IllegalArgumentException("Session ID cannot be null or empty");
        }

        if (limit <= 0) {
            throw new IllegalArgumentException("Limit must be positive");
        }

        List<Episode> episodes = new ArrayList<>();

        try {
            // First try to get from Redis cache
            List<String> episodeIds = getEpisodeIdsFromRedis(sessionId, limit);

            if (episodeIds != null && !episodeIds.isEmpty()) {
                // Retrieve episode objects from Redis HSET
                episodes = retrieveEpisodesFromRedis(episodeIds);
            }

            // If we don't have all episodes in cache, fetch remaining from PostgreSQL
            if (episodes.size() < limit) {
                List<Episode> dbEpisodes = getEpisodesFromPostgreSQL(sessionId, limit - episodes.size());
                for (Episode dbEpisode : dbEpisodes) {
                    if (!episodes.stream().anyMatch(e -> e.getId().equals(dbEpisode.getId()))) {
                        episodes.add(dbEpisode);
                    }
                }
            }

            // Sort by timestamp DESC to ensure order
            episodes.sort((a, b) -> b.getTimestamp().compareTo(a.getTimestamp()));

            // Trim to limit
            if (episodes.size() > limit) {
                episodes = episodes.subList(0, limit);
            }

            return episodes;

        } catch (Exception e) {
            logger.error("Failed to retrieve recent episodes for session: {}", sessionId, e);
            // Fall back to PostgreSQL if Redis fails
            return getEpisodesFromPostgreSQL(sessionId, limit);
        }
    }

    /**
     * Clear expired episodes from PostgreSQL.
     * Redis expiration is automatic via EXPIRE command set during store.
     */
    public void clearExpiredEpisodes() {
        try {
            int ttlDays = getEpisodicRetentionDays();
            long cutoffTime = System.currentTimeMillis() - (ttlDays * 24L * 60L * 60L * 1000L);

            String sql = "DELETE FROM episodes WHERE timestamp < ?";

            try (Connection conn = dataSource.getConnection();
                 PreparedStatement stmt = conn.prepareStatement(sql)) {

                stmt.setTimestamp(1, new Timestamp(cutoffTime));
                int deleted = stmt.executeUpdate();
                logger.info("Cleared {} expired episodes from PostgreSQL", deleted);
            }

        } catch (Exception e) {
            logger.error("Failed to clear expired episodes", e);
            throw new RuntimeException("Failed to clear expired episodes", e);
        }
    }

    /**
     * Store episode to PostgreSQL database.
     */
    private void storeToPostgreSQL(String id, String sessionId, String content, Timestamp timestamp) {
        String sql = "INSERT INTO episodes (id, session_id, content, timestamp) VALUES (?, ?, ?, ?)";

        try (Connection conn = dataSource.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, id);
            stmt.setString(2, sessionId);
            stmt.setString(3, content);
            stmt.setTimestamp(4, timestamp);

            int rowsAffected = stmt.executeUpdate();
            if (rowsAffected == 0) {
                logger.warn("No rows affected when storing episode: {}", id);
            } else {
                logger.debug("Stored episode {} to PostgreSQL", id);
            }

        } catch (Exception e) {
            logger.error("Failed to store episode in PostgreSQL: {}", id, e);
            throw new RuntimeException("Failed to store episode in PostgreSQL", e);
        }
    }

    /**
     * Store episode to Redis using HSET and ZSET patterns.
     * HSET for episode data storage, ZSET for time-indexed session retrieval.
     */
    private void storeToRedis(Episode episode) {
        String episodeId = episode.getId();
        String sessionId = episode.getSessionId();
        long timestamp = episode.getTimestamp().atZone(java.time.ZoneId.systemDefault()).toInstant().toEpochMilli();

        try (Jedis jedis = jedisPool.getResource()) {
            // Get TTL from configuration (in seconds)
            int ttl = configService.getEpisodicRedisTtl();

            // Store episode as HSET with fields for easy access
            Map<String, String> episodeData = new HashMap<>();
            episodeData.put("id", episodeId);
            episodeData.put("sessionId", sessionId);
            episodeData.put("content", episode.getContent());
            episodeData.put("timestamp", String.valueOf(timestamp));

            jedis.hset(EPISODE_HASH_PREFIX + episodeId, episodeData);

            // Add to ZSET for time-ordered retrieval (score = timestamp)
            jedis.zadd(SESSION_INDEX_ZSET + sessionId, timestamp, episodeId);

            // Set TTL on both keys
            jedis.expire(EPISODE_HASH_PREFIX + episodeId, ttl);
            jedis.expire(SESSION_INDEX_ZSET + sessionId, ttl);

            logger.debug("Stored episode {} in Redis with TTL {} seconds", episodeId, ttl);

        } catch (Exception e) {
            logger.warn("Failed to store episode in Redis (PostgreSQL backup is durable): {}", episodeId, e);
            // Don't throw - PostgreSQL backup is durable
        }
    }

    /**
     * Get episode IDs from Redis ZSET ordered by timestamp DESC.
     */
    private List<String> getEpisodeIdsFromRedis(String sessionId, int limit) {
        try (Jedis jedis = jedisPool.getResource()) {
            String key = SESSION_INDEX_ZSET + sessionId;

            // Reverse range for newest first (DESC order)
            List<String> episodeIds = jedis.zrevrange(key, 0, limit - 1);

            if (episodeIds != null) {
                logger.debug("Retrieved {} episode IDs from Redis for session {}", episodeIds.size(), sessionId);
            }

            return episodeIds;

        } catch (Exception e) {
            logger.warn("Failed to get episode IDs from Redis: {}", e.getMessage());
            return null;
        }
    }

    /**
     * Retrieve Episode objects from Redis HSET.
     */
    private List<Episode> retrieveEpisodesFromRedis(List<String> episodeIds) {
        List<Episode> episodes = new ArrayList<>();

        try (Jedis jedis = jedisPool.getResource()) {
            for (String episodeId : episodeIds) {
                Map<String, String> episodeData = jedis.hgetAll(EPISODE_HASH_PREFIX + episodeId);

                if (episodeData != null && !episodeData.isEmpty()) {
                    Episode episode = new Episode();
                    episode.setId(episodeData.get("id"));
                    episode.setSessionId(episodeData.get("sessionId"));
                    episode.setContent(episodeData.get("content"));

                    // Parse timestamp
                    String timestampStr = episodeData.get("timestamp");
                    if (timestampStr != null) {
                        long timestamp = Long.parseLong(timestampStr);
                        LocalDateTime dateTime = LocalDateTime.ofInstant(
                                java.time.Instant.ofEpochMilli(timestamp),
                                java.time.ZoneId.systemDefault()
                        );
                        episode.setTimestamp(dateTime);
                    }

                    episodes.add(episode);
                }
            }

            logger.debug("Retrieved {} episodes from Redis", episodes.size());

        } catch (Exception e) {
            logger.warn("Failed to retrieve episodes from Redis: {}", e.getMessage());
        }

        return episodes;
    }

    /**
     * Get episodes from PostgreSQL fallback.
     */
    private List<Episode> getEpisodesFromPostgreSQL(String sessionId, int limit) {
        List<Episode> episodes = new ArrayList<>();

        String sql = "SELECT id, session_id, content, timestamp FROM episodes " +
                     "WHERE session_id = ? ORDER BY timestamp DESC LIMIT ?";

        try (Connection conn = dataSource.getConnection();
             PreparedStatement stmt = conn.prepareStatement(sql)) {

            stmt.setString(1, sessionId);
            stmt.setInt(2, limit);

            try (ResultSet rs = stmt.executeQuery()) {
                while (rs.next()) {
                    Episode episode = new Episode();
                    episode.setId(rs.getString("id"));
                    episode.setSessionId(rs.getString("session_id"));
                    episode.setContent(rs.getString("content"));

                    Timestamp timestamp = rs.getTimestamp("timestamp");
                    if (timestamp != null) {
                        episode.setTimestamp(timestamp.toLocalDateTime());
                    } else {
                        episode.setTimestamp(LocalDateTime.now());
                    }

                    episodes.add(episode);
                }
            }

            logger.debug("Retrieved {} episodes from PostgreSQL for session {}", episodes.size(), sessionId);

        } catch (Exception e) {
            logger.error("Failed to retrieve episodes from PostgreSQL for session: {}", sessionId, e);
            throw new RuntimeException("Failed to retrieve episodes from PostgreSQL", e);
        }

        return episodes;
    }

    /**
     * Get episodic retention days from configuration.
     */
    private int getEpisodicRetentionDays() {
        // Default to 30 days if configuration doesn't provide one
        return configService.getEpisodicRedisTtl() / (24 * 60 * 60);
    }

    /**
     * Shutdown the service and release resources.
     */
    public void shutdown() {
        if (jedisPool != null) {
            try {
                jedisPool.destroy();
                logger.info("EpisodicMemoryService shutdown complete");
            } catch (Exception e) {
                logger.error("Error during EpisodicMemoryService shutdown", e);
            }
        }
    }
}
