package com.synapse.config;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import jakarta.persistence.EntityManagerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.orm.jpa.JpaTransactionManager;
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean;
import org.springframework.orm.jpa.vendor.HibernateJpaVendorAdapter;
import org.springframework.transaction.PlatformTransactionManager;

import javax.sql.DataSource;
import java.util.Objects;

@Configuration
public class PostgresConfig {

    @Bean
    public DataSource dataSource() {
        HikariConfig config = new HikariConfig();
        config.setJdbcUrl(Objects.requireNonNullElse(
            System.getenv("DB_URL"),
            "jdbc:postgresql://localhost:5432/synapse_memory"
        ));
        config.setUsername(Objects.requireNonNullElse(
            System.getenv("DB_USERNAME"),
            "synapse_user"
        ));
        config.setPassword(Objects.requireNonNullElse(
            System.getenv("DB_PASSWORD"),
            "default_password"
        ));
        config.setDriverClassName("org.postgresql.Driver");
        config.setMaximumPoolSize(10);
        config.setMinimumIdle(5);
        config.setConnectionTimeout(30000);
        config.setIdleTimeout(600000);
        config.setMaxLifetime(1800000);
        config.setPoolName("SynapseHikariPool");

        return new HikariDataSource(config);
    }

    @Bean
    public LocalContainerEntityManagerFactoryBean entityManagerFactory(
            DataSource dataSource) {
        LocalContainerEntityManagerFactoryBean em = new LocalContainerEntityManagerFactoryBean();
        em.setDataSource(dataSource);
        em.setPackagesToScan("com.synapse");
        em.setJpaVendorAdapter(new HibernateJpaVendorAdapter());

        java.util.Properties props = new java.util.Properties();
        props.setProperty("hibernate.ddl_auto", "none");
        props.setProperty("hibernate.show_sql", Objects.requireNonNullElse(
            System.getenv("SHOW_SQL"), "false"
        ));
        props.setProperty("hibernate.dialect", "org.hibernate.dialect.PostgreSQLDialect");

        em.setJpaProperties(props);

        return em;
    }

    @Bean
    public PlatformTransactionManager transactionManager(
            EntityManagerFactory entityManagerFactory) {
        return new JpaTransactionManager(entityManagerFactory);
    }
}
