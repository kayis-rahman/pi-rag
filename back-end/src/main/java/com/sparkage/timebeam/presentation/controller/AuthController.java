package com.sparkage.timebeam.presentation.controller;

import java.util.Map;
import java.util.Optional;

import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.sparkage.timebeam.application.service.AuthService;
import com.sparkage.timebeam.application.service.UserService;
import com.sparkage.timebeam.domain.model.User;
import com.sparkage.timebeam.infrastructure.config.AppLogger;
import com.sparkage.timebeam.presentation.dto.AuthRequests;
import com.sparkage.timebeam.presentation.dto.UserDto;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final UserService userService;
    private final AuthService authService;

    public AuthController(UserService userService, AuthService authService) {
        this.userService = userService;
        this.authService = authService;
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

        // Successful login
        AppLogger.logAuthEvent("login_success", login.getEmail());
        return ResponseEntity.ok(Map.of("accessToken", token.get()));
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
