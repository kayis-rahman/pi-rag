//package com.synapse.memory.episodic;
//
//import com.synapse.memory.Episode;
//import com.synapse.memory.config.MemoryConfigurationService;
//import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.stereotype.Service;
//
//import javax.sql.DataSource;
//import java.sql.*;
//import java.util.ArrayList;
//import java.util.List;
//import java.util.UUID;
//import redis.clients.jedis.Jedis;
//import redis.clients.jedis.JedisPool;
//
//@Service
//public class EpisodicMemoryService {
//
//    @Autowired
//    private DataSource dataSource;
//
//    @Autowired
//    private MemoryConfigurationService configService;
//
//    private JedisPool jedisPool;
//
//    public EpisodicMemoryService() {
//        // Initialize Redis connection pool - will be updated with config
//        this.jedisPool = new JedisPool("localhost", 6379);
//    }
//
//    public void storeEpisode(String sessionId, String content) {
//        try {
//            // Store in PostgreSQL
//            String sql = "INSERT INTO episodes (id, session_id, content, timestamp) VALUES (?, ?, ?, ?)";
//            String id = UUID.randomUUID().toString();
//
//            try (Connection conn = dataSource.getConnection();
//                 PreparedStatement stmt = conn.prepareStatement(sql)) {
//
//                stmt.setString(1, id);
//                stmt.setString(2, sessionId);
//                stmt.setString(3, content);
//                stmt.setTimestamp(4, new Timestamp(System.currentTimeMillis()));
//
//                stmt.executeUpdate();
//            }
//
//            // Store in Redis cache with TTL
//            try (Jedis jedis = jedisPool.getResource()) {
//                String key = "episode:" + id;
//                int ttl = configService.getEpisodicRedisTtl();
//                jedis.setex(key, ttl, content);
//            }
//
//        } catch (Exception e) {
//            throw new RuntimeException("Failed to store episode", e);
//        }
//    }
//
//    public List<Episode> getRecentEpisodes(String sessionId, int limit) {
//        try {
//            // First try to get from Redis cache
//            List<Episode> episodes = new ArrayList<>();
//
//            try (Jedis jedis = jedisPool.getResource()) {
//                // Get recent episode keys from Redis (assuming we maintain a list)
//                String sessionKey = "session:" + sessionId + ":episodes";
//                List<String> episodeKeys = jedis.lrange(sessionKey, 0, limit - 1);
//
//                for (String key : episodeKeys) {
//                    String content = jedis.get(key);
//                    if (content != null) {
//                        // We'd need to deserialize the episode from the key
//                        // This is simplified - in a real implementation we'd need
//                        // to handle proper serialization/deserialization
//                        episodes.add(new Episode(sessionId, content));
//                    }
//                }
//            }
//
//            // If we don't have all episodes in cache, fetch from PostgreSQL
//            if (episodes.size() < limit) {
//                String sql = "SELECT id, session_id, content, timestamp FROM episodes " +
//                           "WHERE session_id = ? ORDER BY timestamp DESC LIMIT ?";
//
//                try (Connection conn = dataSource.getConnection();
//                     PreparedStatement stmt = conn.prepareStatement(sql)) {
//
//                    stmt.setString(1, sessionId);
//                    stmt.setInt(2, limit);
//
//                    try (ResultSet rs = stmt.executeQuery()) {
//                        while (rs.next()) {
//                            Episode episode = new Episode(
//                                rs.getString("session_id"),
//                                rs.getString("content")
//                            );
//                            episodes.add(episode);
//                        }
//                    }
//                }
//            }
//
//            return episodes;
//
//        } catch (Exception e) {
//            throw new RuntimeException("Failed to retrieve episodes", e);
//        }
//    }
//
//    public void clearExpiredEpisodes() {
//        try {
//            // Clear expired entries from Redis
//            try (Jedis jedis = jedisPool.getResource()) {
//                // This is a placeholder - in a real implementation,
//                // we'd need to track which keys are expired
//                jedis.flushAll();
//            }
//
//            // Clear old entries from PostgreSQL (based on timestamp)
//            String sql = "DELETE FROM episodes WHERE timestamp < ?";
//            long cutoffTime = System.currentTimeMillis() - (7 * 24 * 60 * 60 * 1000L); // 7 days
//
//            try (Connection conn = dataSource.getConnection();
//                 PreparedStatement stmt = conn.prepareStatement(sql)) {
//
//                stmt.setTimestamp(1, new Timestamp(cutoffTime));
//                stmt.executeUpdate();
//            }
//
//        } catch (Exception e) {
//            throw new RuntimeException("Failed to clear expired episodes", e);
//        }
//    }
//
//    public void shutdown() {
//        if (jedisPool != null) {
//            jedisPool.close();
//        }
//    }
//}