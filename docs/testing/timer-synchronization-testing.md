# Timer Synchronization Testing Documentation

## Overview

This document outlines the comprehensive testing approach for the timer synchronization functionality in the TimeBeam application. The tests cover both state-based and event-based synchronization mechanisms to ensure reliable cross-device timer synchronization.

## Synchronization Mechanisms

### 1. State-Based Synchronization
- **Push Timer State**: Devices push their current timer state to the backend
- **Pull Timer State**: Devices fetch the latest synchronized timer state
- **Collaborative Mode**: Any device can update the timer state
- **Timestamp-Based Conflict Resolution**: Newer timestamps always win

### 2. Event-Based Synchronization
- **Push Timer Action**: Devices send discrete timer actions (START, PAUSE, RESET, etc.)
- **Event Broadcasting**: Events are broadcast to connected devices
- **Real-time Updates**: Immediate synchronization across devices

## Test Coverage

### TimerSyncService Tests

#### State Management
- **New User Creation**: Verifies creation of timer state for new users
- **Existing User Updates**: Tests updating existing timer states
- **Concurrent Update Handling**: Validates retry logic for optimistic locking failures
- **State Retrieval**: Ensures proper retrieval of timer states

#### Action Processing
- **START Actions**: Tests state updates for timer start operations
- **PAUSE Actions**: Validates pause state handling
- **RESET Actions**: Verifies timer reset functionality
- **STOP Actions**: Tests timer stop operations
- **ADVANCE Actions**: Validates phase advancement

#### Utility Functions
- **Duplicate Cleanup**: Tests removal of duplicate timer states
- **State Clearing**: Verifies user state clearing functionality

### TimerEventService Tests

#### Event Processing
- **Event Creation**: Validates timer event storage
- **Event Broadcasting**: Tests WebSocket and push notification broadcasting
- **Event Retrieval**: Ensures recent events can be retrieved

#### Background Operations
- **Pending Event Processing**: Tests automatic processing of queued events
- **Old Event Cleanup**: Validates deletion of stale events

### Conflict Resolution Tests

#### Timestamp-Based Resolution
- **State Timestamp Comparison**: Validates that newer timestamps take precedence
- **Race Condition Handling**: Tests handling of simultaneous updates

#### Collaborative Control
- **Device Independence**: Ensures any device can update timer state
- **Update Validation**: Confirms proper state updates regardless of source device

## Key Testing Scenarios

### 1. Normal Operation
- Creating new timer states
- Updating existing timer states
- Pulling latest timer states
- Processing timer actions

### 2. Concurrent Access
- Handling optimistic locking failures
- Retry mechanisms for simultaneous updates
- Race condition prevention

### 3. Error Handling
- Graceful handling of database exceptions
- Recovery from network failures
- Logging of synchronization errors

### 4. Edge Cases
- Empty state retrieval
- Duplicate state cleanup
- Stale data management

## Test Execution

The tests are designed to run with Mockito for mocking dependencies and verify:
- Correct method calls and parameter passing
- Proper state transitions
- Exception handling
- Integration between components

## Benefits of Comprehensive Testing

1. **Reliability**: Ensures consistent timer behavior across devices
2. **Data Integrity**: Maintains accurate timer states during synchronization
3. **Performance**: Validates efficient handling of concurrent updates
4. **User Experience**: Guarantees seamless cross-device synchronization
5. **Error Resilience**: Handles network interruptions and failures gracefully

## Running Tests

Execute the timer synchronization tests using standard Maven test commands:

```bash
cd back-end
mvn test -Dtest="*TimerSync*Test"
mvn test -Dtest="*TimerEvent*Test"
mvn test -Dtest="*Synchronization*Test"
```

Or run all tests together:

```bash
cd back-end
mvn test
```