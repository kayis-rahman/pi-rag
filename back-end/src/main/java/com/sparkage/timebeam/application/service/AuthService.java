package com.sparkage.timebeam.application.service;

import com.sparkage.timebeam.infrastructure.persistence.RefreshToken;
import com.sparkage.timebeam.domain.model.User;
import com.sparkage.timebeam.infrastructure.persistence.RefreshTokenRepository;
import com.sparkage.timebeam.domain.repository.UserRepository;
import com.sparkage.timebeam.infrastructure.external.JwtUtils;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
public class AuthService {
    private static final Logger log = LoggerFactory.getLogger(AuthService.class);

    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final JwtUtils jwtUtils;

    public AuthService(UserRepository userRepository, RefreshTokenRepository refreshTokenRepository, JwtUtils jwtUtils) {
        this.userRepository = userRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.jwtUtils = jwtUtils;
    }

    // Simple auth: front-end handles Google Sign-In. Backend accepts email and issues JWT if user exists.
    public Optional<String> login(String email) {
        log.debug("auth.login called for email={}", email);
        Optional<User> userOpt = userRepository.findByEmail(email);
        if (userOpt.isEmpty()) {
            log.info("login failed - user not found for email={}", maskEmail(email));
            return Optional.empty();
        }
        User user = userOpt.get();
        String jwt = jwtUtils.generateToken(user.getId());
        log.info("login success for userId={}", user.getId());
        return Optional.of(jwt);
    }

    public RefreshToken storeRefreshToken(UUID userId, String token, Instant expiresAt) {
        log.debug("storing refresh token for userId={}, expiresAt={}", userId, expiresAt);
        RefreshToken rt = new RefreshToken(UUID.randomUUID(), userId, token, expiresAt);
        return refreshTokenRepository.save(rt);
    }

    public Optional<RefreshToken> findByToken(String token) {
        log.debug("find refresh token called");
        return refreshTokenRepository.findByToken(token);
    }

    public void revokeTokensForUser(UUID userId) {
        log.debug("revoking tokens for userId={}", userId);
        refreshTokenRepository.deleteByUserId(userId);
    }

    private String maskEmail(String email) {
        if (email == null) return "null";
        int at = email.indexOf('@');
        if (at <= 1) return "****" + (at > 0 ? email.substring(at) : "");
        return email.charAt(0) + "****" + email.substring(at);
    }
}
