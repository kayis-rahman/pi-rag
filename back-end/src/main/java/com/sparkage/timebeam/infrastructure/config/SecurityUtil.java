package com.sparkage.timebeam.infrastructure.config;

import java.util.Optional;
import java.util.UUID;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;

public final class SecurityUtil {
    private SecurityUtil() {}

    public static Optional<UUID> getCurrentUserId() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || auth.getName() == null) return Optional.empty();
        try {
            return Optional.of(UUID.fromString(auth.getName()));
        } catch (Exception ex) {
            return Optional.empty();
        }
    }
}
