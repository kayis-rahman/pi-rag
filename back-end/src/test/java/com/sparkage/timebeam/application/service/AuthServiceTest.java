package com.sparkage.timebeam.application.service;

import java.util.Optional;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

import com.sparkage.timebeam.domain.model.User;
import com.sparkage.timebeam.domain.repository.UserRepository;
import com.sparkage.timebeam.infrastructure.external.JwtUtils;
import com.sparkage.timebeam.infrastructure.persistence.RefreshTokenRepository;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

class AuthServiceTest {
    private UserRepository userRepository;
    private RefreshTokenRepository refreshTokenRepository;
    private JwtUtils jwtUtils;
    private AuthService authService;

    @BeforeEach
    void setUp() {
        userRepository = Mockito.mock(UserRepository.class);
        refreshTokenRepository = Mockito.mock(RefreshTokenRepository.class);
        // Use a real JwtUtils to avoid ByteBuddy/mockito inline mocking issues on newer JDKs
        // secret must be at least 32 bytes for HMAC SHA key
        jwtUtils = new JwtUtils("01234567890123456789012345678901", 3600_000L);
        authService = new AuthService(userRepository, refreshTokenRepository, jwtUtils);
    }

    @Test
    void loginReturnsEmptyWhenUserNotFound() {
        when(userRepository.findByEmail(anyString())).thenReturn(Optional.empty());
        var res = authService.login("noone@example.com");
        assertTrue(res.isEmpty());
    }

    @Test
    void loginReturnsTokenWhenUserExists() {
        UUID id = UUID.randomUUID();
        User u = new User(id, "a@b.com", "A", false);
        when(userRepository.findByEmail("a@b.com")).thenReturn(Optional.of(u));

        var res = authService.login("a@b.com");
        assertTrue(res.isPresent());
        String token = res.get();
        // validate token signature and subject
        assertTrue(jwtUtils.validateToken(token));
        assertEquals(id, jwtUtils.parseUserId(token));
    }
}
