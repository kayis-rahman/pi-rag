package com.sparkage.timebeam.presentation.controller;

import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RestController;

import com.sparkage.timebeam.application.service.AuthService;
import com.sparkage.timebeam.application.service.UserService;
import com.sparkage.timebeam.domain.model.User;
import com.sparkage.timebeam.infrastructure.config.AppLogger;
import com.sparkage.timebeam.infrastructure.external.JwtUtils;
import com.sparkage.timebeam.infrastructure.persistence.RefreshToken;
import com.sparkage.timebeam.infrastructure.persistence.RefreshTokenRepository;
import com.sparkage.timebeam.presentation.dto.AuthRequests;
import com.sparkage.timebeam.presentation.dto.UserDto;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final UserService userService;
    private final AuthService authService;
    private final RefreshTokenRepository refreshTokenRepository;
    private final JwtUtils jwtUtils;

    public AuthController(UserService userService, AuthService authService, RefreshTokenRepository refreshTokenRepository, JwtUtils jwtUtils) {
        this.userService = userService;
        this.authService = authService;
        this.refreshTokenRepository = refreshTokenRepository;
        this.jwtUtils = jwtUtils;
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> health() {
        return ResponseEntity.ok(Map.of("status", "ok", "service", "timebeam-backend"));
    }

    @PostMapping("/register")
    public ResponseEntity<UserDto> register(@Validated @RequestBody AuthRequests.Register request) {
        Optional<User> existing = userService.findByEmail(request.getEmail());
        if (existing.isPresent()) {
            return userService.findDtoById(existing.get().getId())
                    .map(ResponseEntity::ok)
                    .orElseGet(() -> ResponseEntity.status(500).build());
        }
        UserDto dto = userService.createUser(request.getEmail(), request.getDisplayName());
        return ResponseEntity.ok(dto);
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@Validated @RequestBody AuthRequests.Login login) {
        // Log incoming attempt at debug level with masked email
        AppLogger.logAuthEvent("login_request", login.getEmail());

        Optional<String> token = authService.login(login.getEmail());
        if (token.isEmpty()) {
            // If no user exists, auto-register and retry login
            AppLogger.logAuthEvent("auto_registration_attempt", login.getEmail());
            String displayName = deriveDisplayName(login.getEmail());
            try {
                UserDto created = userService.createUser(login.getEmail(), displayName);
                AppLogger.logAuthEvent("auto_registration_success", login.getEmail(), created.getId().toString());
                // Retry login
                token = authService.login(login.getEmail());
            } catch (Exception ex) {
                AppLogger.logError("auto_registration", ex, "unknown");
                AppLogger.logAuthEvent("login_failed", login.getEmail());
                Map<String, String> body = Map.of("error", "invalid_credentials");
                return ResponseEntity.status(401).body(body);
            }
        }

        if (token.isEmpty()) {
            AppLogger.logAuthEvent("login_failed", login.getEmail());
            Map<String, String> body = Map.of("error", "invalid_credentials");
            return ResponseEntity.status(401).body(body);
        }

        // Generate refresh token with 7-day expiry
        Optional<User> userOpt = userService.findByEmail(login.getEmail());
        if (userOpt.isEmpty()) {
            AppLogger.logAuthEvent("login_failed", login.getEmail());
            Map<String, String> body = Map.of("error", "user_not_found");
            return ResponseEntity.status(500).body(body);
        }

        User user = userOpt.get();
        String refreshToken = jwtUtils.generateRefreshToken(user.getId());
        Instant refreshTokenExpiresAt = Instant.now().plusSeconds(7 * 24 * 60 * 60); // 7 days
        authService.storeRefreshToken(user.getId(), refreshToken, refreshTokenExpiresAt);

        // Successful login - return user info and tokens
        AppLogger.logAuthEvent("login_success", login.getEmail(), user.getId().toString());
        Optional<UserDto> userDto = userService.findDtoById(user.getId());
        if (userDto.isPresent()) {
            return ResponseEntity.ok(Map.of(
                "accessToken", token.get(),
                "refreshToken", refreshToken,
                "user", userDto.get()
            ));
        } else {
            return ResponseEntity.ok(Map.of(
                "accessToken", token.get(),
                "refreshToken", refreshToken
            ));
        }
    }

    @PostMapping("/refresh")
    public ResponseEntity<?> refresh(@RequestHeader("Authorization") String authorizationHeader) {
        try {
            // Extract token from Bearer header
            if (authorizationHeader == null || !authorizationHeader.startsWith("Bearer ")) {
                AppLogger.logAuthEvent("refresh_token_invalid_format", "<no_token>");
                Map<String, String> body = Map.of("error", "invalid_token");
                return ResponseEntity.status(401).body(body);
            }

            String refreshToken = authorizationHeader.substring(7);

            // Look up the refresh token in database
            Optional<RefreshToken> refreshTokenOpt = refreshTokenRepository.findByToken(refreshToken);
            if (refreshTokenOpt.isEmpty()) {
                AppLogger.logAuthEvent("refresh_token_not_found", "<unknown>");
                Map<String, String> body = Map.of("error", "invalid_token");
                return ResponseEntity.status(401).body(body);
            }

            RefreshToken storedToken = refreshTokenOpt.get();

            // Validate token is not expired
            if (storedToken.getExpiresAt().isBefore(Instant.now())) {
                AppLogger.logAuthEvent("refresh_token_expired", storedToken.getUserId().toString());
                refreshTokenRepository.delete(storedToken);
                Map<String, String> body = Map.of("error", "token_expired");
                return ResponseEntity.status(401).body(body);
            }

            // Generate new JWT access token
            UUID userId = storedToken.getUserId();
            String newAccessToken = jwtUtils.generateToken(userId);

            // Generate new refresh token and store it (rotate refresh tokens for security)
            String newRefreshToken = jwtUtils.generateRefreshToken(userId);
            Instant newRefreshTokenExpiresAt = Instant.now().plusSeconds(7 * 24 * 60 * 60); // 7 days
            authService.storeRefreshToken(userId, newRefreshToken, newRefreshTokenExpiresAt);

            // Log success
            AppLogger.logAuthEvent("refresh_token_success", userId.toString());

            return ResponseEntity.ok(Map.of(
                "accessToken", newAccessToken,
                "refreshToken", newRefreshToken
            ));

        } catch (Exception ex) {
            AppLogger.logError("refresh_token_error", ex, "<unknown>");
            Map<String, String> body = Map.of("error", "invalid_token");
            return ResponseEntity.status(401).body(body);
        }
    }

    private String deriveDisplayName(String email) {
        if (email == null) return "";
        int at = email.indexOf('@');
        String local = at > 0 ? email.substring(0, at) : email;
        local = local.replace('.', ' ').replace('_', ' ');
        if (local.isBlank()) return "User";
        return Character.toUpperCase(local.charAt(0)) + (local.length() > 1 ? local.substring(1) : "");
    }
}
