package com.synapse.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import javax.sql.DataSource;
import java.io.File;
import java.net.URI;
import java.net.URISyntaxException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.function.Supplier;
import jakarta.annotation.PostConstruct;

@Configuration
public class SQLiteConfig {

    @Value("${memory.knowledge.sqlite.path:/var/lib/synapse/knowledge.db}")
    private String sqlitePath;

    @PostConstruct
    public void init() {
        // Ensure database directory exists
        File dbFile = new File(sqlitePath);
        File dbDir = dbFile.getParentFile();
        if (dbDir != null && !dbDir.exists()) {
            boolean created = dbDir.mkdirs();
            if (created) {
                System.out.println("Created SQLite database directory: " + dbDir.getAbsolutePath());
            }
        }
    }

    @Bean
    public DataSource sqliteDataSource() {
        return new DataSource() {
            @Override
            public Connection getConnection() throws SQLException {
                return DriverManager.getConnection("jdbc:sqlite:" + sqlitePath);
            }

            @Override
            public Connection getConnection(String username, String password) throws SQLException {
                return getConnection();
            }

            @Override
            public <T> T unwrap(Class<T> iface) throws SQLException {
                if (iface.isInstance(this)) {
                    return iface.cast(this);
                }
                throw new SQLException("Cannot unwrap to " + iface.getName());
            }

            @Override
            public boolean isWrapperFor(Class<?> iface) throws SQLException {
                return iface.isInstance(this);
            }

            @Override
            public java.io.PrintWriter getLogWriter() throws SQLException {
                return null;
            }

            @Override
            public void setLogWriter(java.io.PrintWriter out) throws SQLException {
            }

            @Override
            public void setLoginTimeout(int seconds) throws SQLException {
            }

            @Override
            public int getLoginTimeout() throws SQLException {
                return 0;
            }

            @Override
            public java.util.logging.Logger getParentLogger() throws java.sql.SQLFeatureNotSupportedException {
                throw new java.sql.SQLFeatureNotSupportedException("getParentLogger not supported");
            }
        };
    }

    @Bean
    public Supplier<Connection> sqliteConnectionSupplier() {
        return () -> {
            try {
                return DriverManager.getConnection("jdbc:sqlite:" + sqlitePath);
            } catch (SQLException e) {
                throw new RuntimeException("Failed to get SQLite connection", e);
            }
        };
    }
}
