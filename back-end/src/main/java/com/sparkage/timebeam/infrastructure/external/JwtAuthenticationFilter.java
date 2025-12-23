package com.sparkage.timebeam.infrastructure.external;

import java.io.IOException;
import java.util.Collections;
import java.util.UUID;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    private static final Logger log = LoggerFactory.getLogger(JwtAuthenticationFilter.class);

    private final JwtUtils jwtUtils;

    public JwtAuthenticationFilter(JwtUtils jwtUtils) {
        this.jwtUtils = jwtUtils;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain) throws ServletException, IOException {
        String authHeader = request.getHeader("Authorization");
        log.debug("🔍 JwtAuthenticationFilter: Authorization header present: {}", authHeader != null ? "YES" : "NO");
        if (authHeader != null) {
            log.debug("🔍 JwtAuthenticationFilter: Header value: {}...", authHeader.substring(0, Math.min(20, authHeader.length())));
        }

        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7);
            try {
                if (jwtUtils.validateToken(token)) {
                    UUID userId = jwtUtils.parseUserId(token);
                    UserDetails principal = User.withUsername(userId.toString()).password("").authorities(Collections.emptyList()).build();
                    UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken(principal, null, principal.getAuthorities());
                    SecurityContextHolder.getContext().setAuthentication(auth);
                    log.debug("✅ JwtAuthenticationFilter: Valid token for user: {}", userId);
                } else {
                    log.debug("❌ JwtAuthenticationFilter: Invalid token");
                }
            } catch (Exception ex) {
                log.debug("❌ JwtAuthenticationFilter: JWT processing error: {}", ex.getMessage());
            }
        } else {
            log.debug("⚠️ JwtAuthenticationFilter: No Bearer token found, proceeding with anonymous authentication");
        }
        filterChain.doFilter(request, response);
    }
}
