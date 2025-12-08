package com.sparkage.timebeam;

import com.sparkage.timebeam.infrastructure.persistence.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import jakarta.annotation.PostConstruct;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.Date;
import java.util.List;
import java.util.UUID;

/**
 * E2E Test Data Seeder
 * Seeds the database with test data for end-to-end testing
 * Creates test users, tasks, sessions, and device registrations
 */
@Component
public class E2ETestDataSeeder {

    @Autowired
    private UserJpaRepository userRepository;

    @Autowired
    private TaskRepository taskRepository;

    @Autowired
    private SessionRecordRepository sessionRecordRepository;

    @Autowired
    private UserDeviceRepository userDeviceRepository;

    @Autowired
    private UserPreferencesRepository userPreferencesRepository;

    @Autowired
    private TimerStateRepository timerStateRepository;

    // Test user credentials (email-based authentication)
    public static final String TEST_USER_EMAIL = "test@example.com";
    public static final String TEST_USER_DISPLAY_NAME = "Test User";
    public static final UUID TEST_USER_ID = UUID.fromString("550e8400-e29b-41d4-a716-446655440000");

    public static final String TEST_USER_2_EMAIL = "test2@example.com";
    public static final String TEST_USER_2_DISPLAY_NAME = "Test User 2";
    public static final UUID TEST_USER_2_ID = UUID.fromString("550e8400-e29b-41d4-a716-446655440001");

    @PostConstruct
    @Transactional
    public void seedE2ETestData() {
        cleanupExistingData();
        seedUsers();
        seedTasks();
        seedSessions();
        seedDevices();
        seedPreferences();
        seedTimerStates();
    }

    @Transactional
    public void cleanupExistingData() {
        timerStateRepository.deleteAll();
        sessionRecordRepository.deleteAll();
        taskRepository.deleteAll();
        userDeviceRepository.deleteAll();
        userPreferencesRepository.deleteAll();
        userRepository.deleteAll();
    }

    private void seedUsers() {
        User testUser = new User(TEST_USER_ID, TEST_USER_EMAIL, TEST_USER_DISPLAY_NAME, false);
        userRepository.save(testUser);

        User testUser2 = new User(TEST_USER_2_ID, TEST_USER_2_EMAIL, TEST_USER_2_DISPLAY_NAME, false);
        userRepository.save(testUser2);
    }

    private void seedTasks() {
        LocalDateTime now = LocalDateTime.now();

        // Test User's tasks
        List<Task> testUserTasks = List.of(
            new Task(
                UUID.fromString("550e8400-e29b-41d4-a716-446655440010"),
                TEST_USER_ID,
                "Complete project documentation",
                "Write comprehensive documentation for the TimeBeam project",
                Task.Status.todo,
                Instant.from(now.minusDays(2)),
                Instant.from(now.minusDays(2))
            ),

            new Task(
                UUID.fromString("550e8400-e29b-41d4-a716-446655440011"),
                TEST_USER_ID,
                "Implement user authentication",
                "Add login/logout functionality with JWT tokens",
                Task.Status.in_progress,
                Instant.from(now.minusDays(1)),
                Instant.from(now.minusHours(2))
            ),

            new Task(
                UUID.fromString("550e8400-e29b-41d4-a716-446655440012"),
                TEST_USER_ID,
                "Set up CI/CD pipeline",
                "Configure automated testing and deployment",
                Task.Status.completed,
                Instant.from(now.minusDays(3)),
                Instant.from(now.minusHours(1))
            ),

            new Task(
                UUID.fromString("550e8400-e29b-41d4-a716-446655440013"),
                TEST_USER_ID,
                "Design user interface",
                "Create wireframes and mockups for the mobile app",
                Task.Status.todo,
                Instant.from(now.minusHours(12)),
                Instant.from(now.minusHours(12))
            )
        );

        taskRepository.saveAll(testUserTasks);

        // Test User 2's tasks
        List<Task> testUser2Tasks = List.of(
            new Task(
                UUID.fromString("550e8400-e29b-41d4-a716-446655440014"),
                TEST_USER_2_ID,
                "Database optimization",
                "Improve query performance and add indexes",
                Task.Status.todo,
                Instant.from(now.minusDays(1)),
                Instant.from(now.minusDays(1))
            )
        );

        taskRepository.saveAll(testUser2Tasks);
    }

    private void seedSessions() {
        LocalDateTime now = LocalDateTime.now();

        List<SessionRecord> sessions = List.of(
            // Yesterday's work session
            new SessionRecord(
                UUID.fromString("550e8400-e29b-41d4-a716-446655440020"),
                TEST_USER_ID,
                null, // deviceId
                UUID.fromString("550e8400-e29b-41d4-a716-446655440011"), // Authentication task
                Instant.from(now.minusDays(1).minusMinutes(30)),
                1800, // 30 minutes
                SessionRecord.Kind.WORK,
                true, // completed
                false, // interrupted
                null, // interruptionReason
                Instant.now()
            ),

            // Yesterday's break
            new SessionRecord(
                UUID.fromString("550e8400-e29b-41d4-a716-446655440021"),
                TEST_USER_ID,
                null, // deviceId
                null, // taskId
                Instant.from(now.minusDays(1).minusMinutes(5)),
                300, // 5 minutes
                SessionRecord.Kind.SHORT_BREAK,
                true, // completed
                false, // interrupted
                null, // interruptionReason
                Instant.now()
            ),

            // Today's work session
            new SessionRecord(
                UUID.fromString("550e8400-e29b-41d4-a716-446655440022"),
                TEST_USER_ID,
                null, // deviceId
                UUID.fromString("550e8400-e29b-41d4-a716-446655440010"), // Documentation task
                Instant.from(now.minusHours(2)),
                7200, // 2 hours
                SessionRecord.Kind.WORK,
                true, // completed
                false, // interrupted
                null, // interruptionReason
                Instant.now()
            ),

            // Long break
            new SessionRecord(
                UUID.fromString("550e8400-e29b-41d4-a716-446655440023"),
                TEST_USER_ID,
                null, // deviceId
                null, // taskId
                Instant.from(now.minusHours(1)),
                1800, // 30 minutes
                SessionRecord.Kind.LONG_BREAK,
                true, // completed
                false, // interrupted
                null, // interruptionReason
                Instant.now()
            )
        );

        sessionRecordRepository.saveAll(sessions);
    }

    private void seedDevices() {
        Instant now = Instant.now();
        List<UserDevice> devices = List.of(
            new UserDevice(
                UUID.fromString("550e8400-e29b-41d4-a716-446655440030"),
                TEST_USER_ID,
                "ios-simulator-test-device",
                "iPhone Simulator",
                "iOS",
                "17.0",
                "1.0.0",
                null, // apnsToken
                "test-fcm-token-ios",
                now,
                true, // active
                now
            ),

            new UserDevice(
                UUID.fromString("550e8400-e29b-41d4-a716-446655440031"),
                TEST_USER_ID,
                "macos-test-device",
                "MacBook Pro",
                "macOS",
                "14.0",
                "1.0.0",
                null, // apnsToken
                "test-fcm-token-macos",
                now,
                true, // active
                now
            ),

            new UserDevice(
                UUID.fromString("550e8400-e29b-41d4-a716-446655440032"),
                TEST_USER_2_ID,
                "ios-device-user2",
                "iPhone 15 Pro",
                "iOS",
                "17.0",
                "1.0.0",
                null, // apnsToken
                "test-fcm-token-user2",
                now,
                true, // active
                now
            )
        );

        userDeviceRepository.saveAll(devices);
    }

    private void seedPreferences() {
        Instant now = Instant.now();
        List<UserPreferences> preferences = List.of(
            new UserPreferences(
                TEST_USER_ID, // userId (also serves as ID)
                25, // workDurationMinutes
                5, // shortBreakMinutes
                15, // longBreakMinutes
                4, // sessionsBeforeLongBreak
                true, // autoStartBreaks
                true, // autoStartWork
                120, // dailyGoalMinutes
                "system", // theme
                true, // soundEnabled
                true, // notificationsEnabled
                now,
                now
            ),

            new UserPreferences(
                TEST_USER_2_ID, // userId (also serves as ID)
                50, // workDurationMinutes
                10, // shortBreakMinutes
                30, // longBreakMinutes
                3, // sessionsBeforeLongBreak
                false, // autoStartBreaks
                false, // autoStartWork
                240, // dailyGoalMinutes
                "dark", // theme
                false, // soundEnabled
                true, // notificationsEnabled
                now,
                now
            )
        );

        userPreferencesRepository.saveAll(preferences);
    }

    private void seedTimerStates() {
        // Current timer state for test user
        TimerState timerState = new TimerState(
            TEST_USER_ID, // userId (also serves as ID)
            "work", // phase
            1500, // remainingSeconds (25 minutes remaining)
            true, // running
            25, // workDurationMinutes
            5, // breakDurationMinutes
            15, // longBreakDurationMinutes
            true, // autoStartNext
            2, // shortBreaksCompleted
            Instant.now(), // lastUpdatedAt
            UUID.fromString("550e8400-e29b-41d4-a716-446655440030"), // updatedByDeviceId (iOS device)
            1L // version
        );

        timerStateRepository.save(timerState);
    }
}
