//package com.sparkage.synapse.infrastructure.persistence;
//
//import java.time.Instant;
//import java.util.List;
//import java.util.Optional;
//import java.util.UUID;
//
//import org.junit.jupiter.api.BeforeEach;
//import org.junit.jupiter.api.Test;
//import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
//import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;
//import org.springframework.test.context.ActiveProfiles;
//
//import static org.assertj.core.api.Assertions.assertThat;
//
//@DataJpaTest
//@ActiveProfiles("test")
//class TimerStateRepositoryIT {
//
//    @Autowired
//    private TestEntityManager entityManager;
//
//    @Autowired
//    private TimerStateRepository timerStateRepository;
//
//    private UUID userId;
//    private UUID deviceId;
//    private TimerState timerState;
//
//    @BeforeEach
//    void setUp() {
//        userId = UUID.randomUUID();
//        deviceId = UUID.randomUUID();
//
//        timerState = new TimerState();
//        timerState.setUserId(userId);
//        timerState.setPhase("work");
//        timerState.setRemainingSeconds(1500);
//        timerState.setRunning(true);
//        timerState.setWorkDurationMinutes(25);
//        timerState.setBreakDurationMinutes(5);
//        timerState.setLongBreakDurationMinutes(15);
//        timerState.setAutoStartNext(false);
//        timerState.setShortBreaksCompleted(0);
//        timerState.setLastUpdatedAt(Instant.now());
//        timerState.setUpdatedByDeviceId(deviceId);
//        timerState.setVersion(1L);
//    }
//
//    @Test
//    void saveAndFindByUserId_ShouldPersistAndRetrieveTimerState() {
//        // When
//        timerStateRepository.save(timerState);
//        entityManager.flush();
//        entityManager.clear();
//
//        // Then
//        Optional<TimerState> found = timerStateRepository.findByUserId(userId);
//        assertThat(found).isPresent();
//        assertThat(found.get().getUserId()).isEqualTo(userId);
//        assertThat(found.get().getPhase()).isEqualTo("work");
//        assertThat(found.get().getRemainingSeconds()).isEqualTo(1500);
//        assertThat(found.get().isRunning()).isTrue();
//    }
//
//    @Test
//    void existsByUserId_ShouldReturnTrue_WhenTimerStateExists() {
//        // Given
//        timerStateRepository.save(timerState);
//        entityManager.flush();
//
//        // When
//        boolean exists = timerStateRepository.existsByUserId(userId);
//
//        // Then
//        assertThat(exists).isTrue();
//    }
//
//    @Test
//    void existsByUserId_ShouldReturnFalse_WhenTimerStateDoesNotExist() {
//        // When
//        boolean exists = timerStateRepository.existsByUserId(userId);
//
//        // Then
//        assertThat(exists).isFalse();
//    }
//
//    @Test
//    void findStaleTimerStates_ShouldReturnOldTimerStates() {
//        // Given
//        Instant oldTimestamp = Instant.now().minusSeconds(8 * 24 * 60 * 60); // 8 days ago
//        timerState.setLastUpdatedAt(oldTimestamp);
//        timerStateRepository.save(timerState);
//
//        // Create a recent timer state
//        UUID recentUserId = UUID.randomUUID();
//        TimerState recentState = createTimerState(recentUserId, Instant.now());
//        timerStateRepository.save(recentState);
//
//        entityManager.flush();
//
//        // When
//        Instant cutoff = Instant.now().minusSeconds(7 * 24 * 60 * 60); // 7 days ago
//        List<TimerState> staleStates = timerStateRepository.findStaleTimerStates(cutoff);
//
//        // Then
//        assertThat(staleStates).hasSize(1);
//        assertThat(staleStates.get(0).getUserId()).isEqualTo(userId);
//    }
//
//    @Test
//    void findByUpdatedByDeviceId_ShouldReturnTimerStatesForDevice() {
//        // Given
//        timerStateRepository.save(timerState);
//
//        // Create another timer state for same device
//        UUID anotherUserId = UUID.randomUUID();
//        TimerState anotherState = createTimerState(anotherUserId, Instant.now());
//        anotherState.setUpdatedByDeviceId(deviceId);
//        timerStateRepository.save(anotherState);
//
//        // Create timer state for different device
//        UUID differentDeviceId = UUID.randomUUID();
//        UUID thirdUserId = UUID.randomUUID();
//        TimerState thirdState = createTimerState(thirdUserId, Instant.now());
//        thirdState.setUpdatedByDeviceId(differentDeviceId);
//        timerStateRepository.save(thirdState);
//
//        entityManager.flush();
//
//        // When
//        List<TimerState> deviceStates = timerStateRepository.findByUpdatedByDeviceId(deviceId);
//
//        // Then
//        assertThat(deviceStates).hasSize(2);
//        assertThat(deviceStates.stream().map(TimerState::getUserId))
//            .containsExactlyInAnyOrder(userId, anotherUserId);
//    }
//
//    @Test
//    void deleteById_ShouldRemoveTimerState() {
//        // Given
//        timerStateRepository.save(timerState);
//        entityManager.flush();
//
//        // Verify it exists
//        assertThat(timerStateRepository.existsByUserId(userId)).isTrue();
//
//        // When
//        timerStateRepository.deleteById(userId);
//        entityManager.flush();
//
//        // Then
//        assertThat(timerStateRepository.existsByUserId(userId)).isFalse();
//    }
//
//    @Test
//    void versionField_ShouldIncrementOnUpdates() {
//        // Given
//        TimerState saved = timerStateRepository.save(timerState);
//        entityManager.flush();
//        Long initialVersion = saved.getVersion();
//
//        // When - Update the state
//        saved.setRemainingSeconds(1200);
//        TimerState updated = timerStateRepository.save(saved);
//        entityManager.flush();
//
//        // Then
//        assertThat(updated.getVersion()).isGreaterThan(initialVersion);
//    }
//
//    @Test
//    void findByUserIdWithLock_ShouldAcquirePessimisticLock() {
//        // Given
//        timerStateRepository.save(timerState);
//        entityManager.flush();
//        entityManager.clear();
//
//        // When
//        Optional<TimerState> lockedState = timerStateRepository.findByUserIdWithLock(userId);
//
//        // Then
//        assertThat(lockedState).isPresent();
//        assertThat(lockedState.get().getUserId()).isEqualTo(userId);
//        // The pessimistic lock is tested by the fact that this query succeeds
//    }
//
//    @Test
//    void multipleTimerStatesForDifferentUsers_ShouldBeIsolated() {
//        // Given
//        timerStateRepository.save(timerState);
//
//        UUID anotherUserId = UUID.randomUUID();
//        TimerState anotherState = createTimerState(anotherUserId, Instant.now());
//        timerStateRepository.save(anotherState);
//
//        entityManager.flush();
//
//        // When & Then
//        Optional<TimerState> firstState = timerStateRepository.findByUserId(userId);
//        Optional<TimerState> secondState = timerStateRepository.findByUserId(anotherUserId);
//
//        assertThat(firstState).isPresent();
//        assertThat(secondState).isPresent();
//        assertThat(firstState.get().getUserId()).isNotEqualTo(secondState.get().getUserId());
//    }
//
//    private TimerState createTimerState(UUID userId, Instant timestamp) {
//        TimerState state = new TimerState();
//        state.setUserId(userId);
//        state.setPhase("work");
//        state.setRemainingSeconds(1500);
//        state.setRunning(true);
//        state.setWorkDurationMinutes(25);
//        state.setBreakDurationMinutes(5);
//        state.setLongBreakDurationMinutes(15);
//        state.setAutoStartNext(false);
//        state.setShortBreaksCompleted(0);
//        state.setLastUpdatedAt(timestamp);
//        state.setUpdatedByDeviceId(UUID.randomUUID());
//        state.setVersion(1L);
//        return state;
//    }
//}
