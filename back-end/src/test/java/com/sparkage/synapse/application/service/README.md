# Synapse Synchronization Testing

This directory contains comprehensive unit tests for the timer synchronization functionality in Synapse, ensuring reliable cross-device timer state synchronization.

## Test Structure

### 1. TimerSyncServiceTest
- Tests state-based synchronization (push/pull operations)
- Validates concurrent update handling with retry logic
- Tests creation and updating of timer states
- Verifies device-based notification broadcasting

### 2. TimerEventServiceTest
- Tests event-based synchronization mechanisms
- Validates timer action processing
- Tests real-time event broadcasting via WebSocket
- Verifies background event processing and cleanup

### 3. SynchronizationConflictResolutionTest
- Tests timestamp-based conflict resolution
- Validates collaborative control between devices
- Tests optimistic locking failure recovery
- Ensures proper handling of concurrent access scenarios

## Key Features Tested

- **State Synchronization**: Push and pull operations for timer states
- **Event Synchronization**: START, PAUSE, RESET, STOP, and ADVANCE actions
- **Conflict Resolution**: Timestamp-based resolution for concurrent updates
- **Collaborative Mode**: Any device can control timer state
- **Retry Logic**: Automatic retry for concurrent update failures
- **Data Integrity**: Proper state management and cleanup

## Running Tests

```bash
cd back-end
mvn test -Dtest="com.sparkage.synapse.application.service.*Test"
```

## Documentation

For detailed testing approach and scenarios, see:
- [Timer Synchronization Testing](docs/testing/timer-synchronization-testing.md)