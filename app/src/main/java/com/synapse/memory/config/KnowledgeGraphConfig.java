package com.synapse.memory.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;

import javax.sql.DataSource;
import java.io.File;

/**
 * Spring configuration for Knowledge Graph SQLite database.
 * Provides DataSource bean and schema initialization on startup.
 */
@Configuration
public class KnowledgeGraphConfig {

    private static final Logger logger = LoggerFactory.getLogger(KnowledgeGraphConfig.class);

    @Value("${memory.knowledge.sqlite.path:/var/lib/synapse/knowledge.db}")
    private String sqlitePath;

    /**
     * Create and configure SQLite DataSource for knowledge graph.
     * Uses DriverManagerDataSource which is suitable for SQLite (single-threaded).
     */
    @Bean
    public DataSource knowledgeGraphDataSource() {
        logger.info("Configuring SQLite DataSource at: {}", sqlitePath);

        DriverManagerDataSource dataSource = new DriverManagerDataSource();
        dataSource.setDriverClassName("org.sqlite.JDBC");
        dataSource.setUrl("jdbc:sqlite:" + sqlitePath);

        return dataSource;
    }

    /**
     * Create JdbcTemplate bean for SQL operations.
     * Provides Spring abstraction for JDBC operations.
     */
    @Bean
    public JdbcTemplate knowledgeGraphJdbcTemplate(DataSource knowledgeGraphDataSource) {
        return new JdbcTemplate(knowledgeGraphDataSource);
    }

    /**
     * Initialize database schema on startup.
     * Creates graph_edges and graph_entities tables with composite indexes.
     */
    @Bean
    public InitializingBean initializeKnowledgeGraphSchema(JdbcTemplate knowledgeGraphJdbcTemplate) {
        return () -> {
            try {
                // Ensure database directory exists
                File dbFile = new File(sqlitePath);
                File dbDir = dbFile.getParentFile();
                if (dbDir != null && !dbDir.exists()) {
                    if (dbDir.mkdirs()) {
                        logger.info("Created SQLite database directory: {}", dbDir.getAbsolutePath());
                    }
                }

                initializeSchema(knowledgeGraphJdbcTemplate);
                logger.info("Knowledge graph schema initialized successfully");
            } catch (Exception e) {
                logger.error("Failed to initialize knowledge graph schema", e);
                // Log but don't fail startup - schema may already exist
            }
        };
    }

    /**
     * Execute schema initialization DDL statements.
     * Creates graph_edges and graph_entities tables with appropriate indexes.
     */
    private void initializeSchema(JdbcTemplate jdbcTemplate) {
        // Create graph_entities table
        String createEntitiesSql = """
            CREATE TABLE IF NOT EXISTS graph_entities (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                entity_type TEXT NOT NULL,
                entity_id TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(entity_type, entity_id)
            )
            """;

        // Create graph_edges table with triple store structure
        String createEdgesSql = """
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
            """;

        // Create composite index on source for fast forward queries
        String createSourceIndexSql = """
            CREATE INDEX IF NOT EXISTS idx_source
            ON graph_edges(source_type, source_id)
            """;

        // Create composite index on target for fast backward queries
        String createTargetIndexSql = """
            CREATE INDEX IF NOT EXISTS idx_target
            ON graph_edges(target_type, target_id)
            """;

        try {
            jdbcTemplate.execute(createEntitiesSql);
            logger.debug("graph_entities table created or already exists");

            jdbcTemplate.execute(createEdgesSql);
            logger.debug("graph_edges table created or already exists");

            jdbcTemplate.execute(createSourceIndexSql);
            logger.debug("idx_source index created or already exists");

            jdbcTemplate.execute(createTargetIndexSql);
            logger.debug("idx_target index created or already exists");
        } catch (Exception e) {
            logger.warn("Error during schema initialization (may be expected if schema already exists)", e);
        }
    }
}
