package com.synapse.health;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.HealthIndicator;
import org.springframework.boot.actuate.health.Status;
import org.springframework.stereotype.Component;

import java.sql.Connection;
import java.sql.DriverManager;
import javax.sql.DataSource;
import org.springframework.data.redis.connection.RedisConnectionFactory;

/**
 * Health indicator that checks the status of all three databases:
 * - PostgreSQL (for JPA entities and episodic memory)
 * - Redis (for episodic memory cache with TTL)
 * - SQLite (for knowledge graph)
 */
@Component
public class MultiDatabaseHealthIndicator implements HealthIndicator {

    private final DataSource postgresDataSource;
    private final RedisConnectionFactory redisConnectionFactory;

    @Value("${memory.knowledge.sqlite.path:/var/lib/synapse/knowledge.db}")
    private String sqlitePath;

    public MultiDatabaseHealthIndicator(
            DataSource postgresDataSource,
            RedisConnectionFactory redisConnectionFactory) {
        this.postgresDataSource = postgresDataSource;
        this.redisConnectionFactory = redisConnectionFactory;
    }

    @Override
    public Health health() {
        Health postgresqlHealth = checkPostgreSQL();
        Health redisHealth = checkRedis();
        Health sqliteHealth = checkSQLite();

        Status postgresqlStatus = postgresqlHealth.getStatus();
        Status redisStatus = redisHealth.getStatus();
        Status sqliteStatus = sqliteHealth.getStatus();

        boolean allUp = (postgresqlStatus == Status.UP) &&
                        (redisStatus == Status.UP) &&
                        (sqliteStatus == Status.UP);

        Health.Builder builder = allUp ? Health.up() : Health.down();
        builder.withDetail("postgresql", postgresqlHealth);
        builder.withDetail("redis", redisHealth);
        builder.withDetail("sqlite", sqliteHealth);

        return builder.build();
    }

    /**
     * Check PostgreSQL connection health using DataSource
     */
    private Health checkPostgreSQL() {
        try (Connection conn = postgresDataSource.getConnection()) {
            boolean isValid = conn.isValid(5);
            if (isValid) {
                return Health.up().withDetail("connection", "valid").build();
            } else {
                return Health.down().withDetail("connection", "invalid").build();
            }
        } catch (Exception e) {
            return Health.down().withDetail("error", e.getMessage()).build();
        }
    }

    /**
     * Check Redis connection health using RedisConnectionFactory
     */
    private Health checkRedis() {
        try (var connection = redisConnectionFactory.getConnection()) {
            connection.ping();
            return Health.up().withDetail("ping", "ok").build();
        } catch (Exception e) {
            return Health.down().withDetail("error", e.getMessage()).build();
        }
    }

    /**
     * Check SQLite connection health using DriverManager
     */
    private Health checkSQLite() {
        try (Connection conn = DriverManager.getConnection("jdbc:sqlite:" + sqlitePath)) {
            boolean isValid = conn.isValid(5);
            if (isValid) {
                return Health.up().withDetail("connection", "valid").build();
            } else {
                return Health.down().withDetail("connection", "invalid").build();
            }
        } catch (Exception e) {
            return Health.down().withDetail("error", e.getMessage()).build();
        }
    }
}
