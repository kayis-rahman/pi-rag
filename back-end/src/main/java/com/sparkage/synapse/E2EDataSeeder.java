package com.sparkage.synapse;

import com.sparkage.synapse.infrastructure.persistence.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import jakarta.annotation.PostConstruct;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Component
@Profile("e2e")
public class E2EDataSeeder {

    public static final String TEST_USER_EMAIL = "test@example.com";
    public static final UUID TEST_USER_ID = UUID.fromString("550e8400-e29b-41d4-a716-446655440000");

    @Autowired
    private UserJpaRepository userRepository;

    @Autowired
    private UserDeviceRepository userDeviceRepository;

    @PostConstruct
    @Transactional
    public void seed() {
        User user = userRepository.findByEmail(TEST_USER_EMAIL)
            .orElseGet(() -> new User(TEST_USER_ID, TEST_USER_EMAIL, "Test User", false));
        userRepository.save(user);
        UUID userId = user.getId();

        Instant now = Instant.now();
        List<UserDevice> devices = List.of(
            UserDevice.builder()
                .id(UUID.fromString("550e8400-e29b-41d4-a716-446655440030"))
                .userId(userId)
                .deviceId("ios-physical-device")
                .deviceName("iPhone 15 Pro")
                .deviceType("iOS")
                .platform("iOS")
                .active(true)
                .lastSeenAt(now)
                .apnsToken("e2e0000000000000000000000000000000000000000000000000000000000000")
                .createdAt(now)
                .updatedAt(now)
                .build(),

            UserDevice.builder()
                .id(UUID.fromString("550e8400-e29b-41d4-a716-446655440031"))
                .userId(userId)
                .deviceId("macos-native-device")
                .deviceName("MacBook Pro")
                .deviceType("macOS")
                .platform("macOS")
                .active(true)
                .lastSeenAt(now)
                .apnsToken("e2e1111111111111111111111111111111111111111111111111111111111111")
                .createdAt(now)
                .updatedAt(now)
                .build()
        );

        userDeviceRepository.saveAll(devices);
    }
}
