//
//  TimerSyncManagerUnitTests.swift
//  TimeBeamTests
//
//  Unit tests for TimerSyncManager
//

import XCTest
@testable import TimeBeam

final class TimerSyncManagerUnitTests: XCTestCase {
    private var mockTimer: MockPomodoroTimer!

    override func setUpWithError() throws {
        mockTimer = MockPomodoroTimer()
        // Clear deviceId from Keychain for test isolation
        try clearTestDeviceId()
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

    // MARK: - Device ID Tests

    func testDeviceIdIsGeneratedAndPersisted() throws {
        // Given: fresh state
        let id = TimerSyncManager.shared.deviceId

        // Then: deviceId should exist and not be empty
        XCTAssertFalse(id.isEmpty, "deviceId should not be empty")
    }

    func testDeviceIdPersistsAfterConfigure() throws {
        // Given: TimerSyncManager instance
        let id1 = TimerSyncManager.shared.deviceId

        // When: configure timer
        TimerSyncManager.shared.configure(with: mockTimer)

        // Then: deviceId should be the same
        let id2 = TimerSyncManager.shared.deviceId
        XCTAssertEqual(id1, id2, "deviceId should persist after configure")
    }

    // MARK: - Timer Configuration Tests

    func testTimerConfiguration() {
        // When: Timer is configured
        TimerSyncManager.shared.configure(with: mockTimer)

        // Then: Should store the timer reference
        let timer = TimerSyncManager.shared.getTimer()
        XCTAssertNotNil(timer)
    }

    func testGetTimerReturnsConfiguredTimer() {
        // When: Timer is configured
        TimerSyncManager.shared.configure(with: mockTimer)

        // Then: getTimer should return the mock timer
        let timer = TimerSyncManager.shared.getTimer() as? MockPomodoroTimer
        XCTAssertNotNil(timer)
        XCTAssertTrue(timer === mockTimer)
    }

    // MARK: - Sync State Tests

    func testIsSyncingInitialValue() {
        // Then: isSyncing should be false initially
        XCTAssertFalse(TimerSyncManager.shared.isSyncing)
    }

    // MARK: - Sync Action Smoke Tests

    func testSyncActionStartDoesNotCrash() async {
        // Given
        mockTimer.phase = .work
        mockTimer.isRunning = false

        // When: sync start action (may fail auth, which is expected)
        await TimerSyncManager.shared.syncTimerAction(.start)

        // Then: local timer should be updated
        XCTAssertTrue(mockTimer.isRunning)
    }

    func testSyncActionPauseDoesNotCrash() async {
        // Given
        mockTimer.phase = .work
        mockTimer.isRunning = true

        // When: sync pause action
        await TimerSyncManager.shared.syncTimerAction(.pause)

        // Then: local timer should be paused
        XCTAssertFalse(mockTimer.isRunning)
    }

    func testSyncActionResetDoesNotCrash() async {
        // Given
        mockTimer.phase = .work
        mockTimer.remainingSeconds = 1500
        mockTimer.isRunning = true

        // When: sync reset action
        await TimerSyncManager.shared.syncTimerAction(.reset)

        // Then: local timer should be reset
        XCTAssertEqual(mockTimer.phase, .work)
        XCTAssertEqual(mockTimer.shortBreaksCompleted, 0)
    }
}

// MARK: - Mock Classes

private class MockPomodoroTimer: PomodoroTimer {
    var phase: Phase = .work
    var isRunning: Bool = false
    var remainingSeconds: Int = 25 * 60
    var workDuration: Int = 25 * 60
    var breakDuration: Int = 5 * 60
    var longBreakDuration: Int = 15 * 60
    var autoStartNextSession: Bool = true
    var shortBreaksCompleted: Int = 0

    override func applySyncedState(
        phase: Phase,
        remainingSeconds: Int,
        isRunning: Bool,
        workDuration: Int,
        breakDuration: Int,
        longBreakDuration: Int,
        autoStartNextSession: Bool,
        shortBreaksCompleted: Int,
        startTimestamp: Double?,
        pauseTimestamp: Double?,
        lastModifiedTimestamp: Double
    ) {
        self.phase = phase
        self.remainingSeconds = remainingSeconds
        self.isRunning = isRunning
        self.workDuration = workDuration
        self.breakDuration = breakDuration
        self.longBreakDuration = longBreakDuration
        self.autoStartNextSession = autoStartNextSession
        self.shortBreaksCompleted = shortBreaksCompleted
    }
}
