package com.sparkage.timebeam.controller;

import com.sparkage.timebeam.dto.AuthRequests;
import com.sparkage.timebeam.dto.UserDto;
import com.sparkage.timebeam.model.User;
import com.sparkage.timebeam.service.AuthService;
import com.sparkage.timebeam.service.UserService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/auth")
public class AuthController {
    private static final Logger log = LoggerFactory.getLogger(AuthController.class);

    private final UserService userService;
    private final AuthService authService;

    public AuthController(UserService userService, AuthService authService) {
        this.userService = userService;
        this.authService = authService;
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
        // Log incoming attempt at debug level with non-sensitive data
        log.debug("Login request received for email={}", login.getEmail());

        Optional<String> token = authService.login(login.getEmail());
        if (token.isEmpty()) {
            // If no user exists, auto-register and retry login
            log.debug("No existing user found for email={} - attempting auto-registration", login.getEmail());
            String displayName = deriveDisplayName(login.getEmail());
            try {
                UserDto created = userService.createUser(login.getEmail(), displayName);
                log.info("Auto-registered user id={} email={}", created.getId(), maskEmail(created.getEmail()));
                // Retry login
                token = authService.login(login.getEmail());
            } catch (Exception ex) {
                log.error("Auto-registration failed for email={}", login.getEmail(), ex);
                // Detailed debug for developers, and an info-level audit-friendly log with masked email
                log.debug("Login failed for email={}", login.getEmail());
                log.info("Failed login attempt for email={}", maskEmail(login.getEmail()));
                Map<String, String> body = Map.of("error", "invalid_credentials");
                log.debug("Returning unauthorized response: status=401, body={}", body);
                log.info("Returning unauthorized response for email={}", maskEmail(login.getEmail()));
                return ResponseEntity.status(401).body(body);
            }
        }

        if (token.isEmpty()) {
            // Detailed debug for developers, and an info-level audit-friendly log with masked email
            log.debug("Login failed for email={}", login.getEmail());
            log.info("Failed login attempt for email={}", maskEmail(login.getEmail()));
            Map<String, String> body = Map.of("error", "invalid_credentials");
            log.debug("Returning unauthorized response: status=401, body={}", body);
            log.info("Returning unauthorized response for email={}", maskEmail(login.getEmail()));
            return ResponseEntity.status(401).body(body);
        }

        // Successful login
        log.info("User logged in successfully: email={}", maskEmail(login.getEmail()));
        return ResponseEntity.ok(Map.of("accessToken", token.get()));
    }

    // Helper to mask an email address for logs (keeps first char and domain)
    private String maskEmail(String email) {
        if (email == null) return "null";
        int at = email.indexOf('@');
        if (at <= 1) return "****" + (at > 0 ? email.substring(at) : "");
        return email.charAt(0) + "****" + email.substring(at);
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
