//
//  TimerSyncIntegrationTests.swift
//  SynapseTests
//
//  Integration tests for timer synchronization
//

import XCTest
@testable import Synapse

@MainActor
final class TimerSyncIntegrationTests: XCTestCase {

    private var mockTimer: PomodoroTimer!

    override func setUpWithError() throws {
        mockTimer = PomodoroTimer()
        // Clear deviceId from Keychain for test isolation
        try clearTestDeviceId()
        // Reset singleton state
        let syncManager = TimerSyncManager.shared
        syncManager.configure(with: mockTimer)
    }

    override func tearDownWithError() throws {
        try clearTestDeviceId()
    }

    private func clearTestDeviceId() throws {
        do {
            try KeychainStore.clear(.deviceId)
        } catch {
            // Ignore — test isolation
        }
    }

    // MARK: - Device ID Persistence

    func testDeviceIdPersistsAcrossInstances() throws {
        // Given - create two TimerSyncManager instances
        let id1 = TimerSyncManager.shared.deviceId

        // When - create a new instance (simulating app relaunch)
        let id2 = TimerSyncManager.shared.deviceId

        // Then - same deviceId should exist
        XCTAssertFalse(id1.isEmpty, "deviceId should not be empty")
        XCTAssertEqual(id1, id2, "deviceId should persist across instances")
    }

    // MARK: - Timer Action Sync

    func testSyncTimerActionStart() async throws {
        // Given
        mockTimer.phase = .work
        mockTimer.remainingSeconds = 25 * 60
        mockTimer.isRunning = false

        // When - sync start action
        await TimerSyncManager.shared.syncTimerAction(.start)

        // Then - local timer should be running
        XCTAssertTrue(mockTimer.isRunning, "Timer should be running after start")
        XCTAssertNotNil(mockTimer.startTimestamp, "Start timestamp should be set")
    }

    func testSyncTimerActionPause() async throws {
        // Given
        mockTimer.phase = .work
        mockTimer.isRunning = true

        // When - sync pause action
        await TimerSyncManager.shared.syncTimerAction(.pause)

        // Then - local timer should be paused
        XCTAssertFalse(mockTimer.isRunning, "Timer should be paused")
    }

    func testSyncTimerActionReset() async throws {
        // Given
        mockTimer.phase = .work
        mockTimer.remainingSeconds = 1500
        mockTimer.isRunning = true
        mockTimer.shortBreaksCompleted = 2

        // When - sync reset action
        await TimerSyncManager.shared.syncTimerAction(.reset)

        // Then - local timer should be reset
        XCTAssertEqual(mockTimer.phase, .work, "Phase should be work after reset")
        XCTAssertEqual(mockTimer.remainingSeconds, 25 * 60, "Remaining seconds should be default")
        XCTAssertEqual(mockTimer.shortBreaksCompleted, 0, "Breaks completed should be 0 after reset")
        XCTAssertFalse(mockTimer.isRunning, "Timer should not be running after reset")
    }

    // MARK: - Incoming Action Handling

    func testApplyIncomingActionFromOtherDevice() {
        // Given
        mockTimer.phase = .work
        mockTimer.isRunning = true
        let otherDeviceId = "other-device-uuid"

        // When - apply incoming action from another device
        TimerSyncManager.shared.applyIncomingAction(
            "pause",
            phase: "work",
            isRunning: false,
            workDuration: 25,
            breakDuration: 5,
            longBreakDuration: 15,
            autoStartNextSession: false,
            shortBreaksCompleted: 0,
            sourceDeviceId: otherDeviceId,
            timestamp: Date().timeIntervalSince1970
        )

        // Then - local timer should be paused
        XCTAssertFalse(mockTimer.isRunning, "Timer should be paused by incoming action")
    }

    func testIgnoreOwnIncomingAction() {
        // Given
        mockTimer.phase = .work
        mockTimer.isRunning = true
        let ownDeviceId = TimerSyncManager.shared.deviceId

        // When - apply incoming action from own device
        TimerSyncManager.shared.applyIncomingAction(
            "pause",
            phase: "work",
            isRunning: false,
            workDuration: 25,
            breakDuration: 5,
            longBreakDuration: 15,
            autoStartNextSession: false,
            shortBreaksCompleted: 0,
            sourceDeviceId: ownDeviceId,
            timestamp: Date().timeIntervalSince1970
        )

        // Then - local timer should NOT be updated (own actions ignored)
        XCTAssertTrue(mockTimer.isRunning, "Own action should be ignored")
    }

    // MARK: - Watch Connectivity

    func testApplyIncomingStateFromWatch() {
        // Given
        mockTimer.phase = .work
        mockTimer.isRunning = false
        mockTimer.remainingSeconds = 25 * 60
        let watchTimestamp = Date().timeIntervalSince1970 + 100 // future timestamp

        // When - apply incoming state from watch
        TimerSyncManager.shared.applyIncomingState([
            "phase": "break",
            "remainingSeconds": 300,
            "isRunning": true,
            "workDuration": 25,
            "breakDuration": 5,
            "longBreakDuration": 15,
            "autoStartNextSession": false,
            "shortBreaksCompleted": 1,
            "lastModifiedTimestamp": watchTimestamp
        ])

        // Then - local timer should be updated
        XCTAssertEqual(mockTimer.phase, .break, "Phase should be updated")
        XCTAssertEqual(mockTimer.remainingSeconds, 300, "Remaining seconds should be updated")
        XCTAssertTrue(mockTimer.isRunning, "Timer should be running")
    }
}
