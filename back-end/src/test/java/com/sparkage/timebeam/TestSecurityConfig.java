package com.sparkage.timebeam;

import com.sparkage.timebeam.infrastructure.external.PushNotificationService;
import org.mockito.Mockito;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.context.annotation.Profile;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;

import java.util.UUID;

/**
 * Test security configuration that provides a mock authenticated user for integration tests
 */
@Configuration
@EnableWebSecurity
@EnableMethodSecurity(prePostEnabled = false) // Disable method security for tests
@Profile("test")
public class TestSecurityConfig {

    private static final String TEST_USER_ID = "88475a64-7bd3-45ff-a33e-d1617c1e349e"; // Same as test user ID

    @Bean
    @Primary // Make this take precedence over the main security config
    public SecurityFilterChain testFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf().disable()
            .authorizeHttpRequests()
                .anyRequest().permitAll(); // Allow all requests for tests

        return http.build();
    }

    @Bean
    @ConditionalOnMissingBean // Only create if not already exists
    public UserDetailsService userDetailsService() {
        UserDetails user = User.builder()
                .username(TEST_USER_ID) // User ID as username for Principal resolution
                .password("password")
                .roles("USER")
                .build();

        return new InMemoryUserDetailsManager(user);
    }

    @Bean
    @Primary
    public PushNotificationService pushNotificationService() {
        // Mock implementation for tests
        return Mockito.mock(PushNotificationService.class);
    }
}
