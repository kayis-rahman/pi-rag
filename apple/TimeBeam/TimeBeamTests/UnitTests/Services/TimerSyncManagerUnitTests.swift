//
//  TimerSyncManagerUnitTests.swift
//  TimeBeamTests
//
//  Unit tests for TimerSyncManager
//

import XCTest
@testable import TimeBeam

@MainActor
final class TimerSyncManagerUnitTests: XCTestCase {
    private var mockTimer: PomodoroTimer!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockTimer = PomodoroTimer()
        // Clear deviceId from Keychain for test isolation
        try? clearTestDeviceId()
        let syncManager = TimerSyncManager.shared
        syncManager.configure(with: mockTimer)
    }

    override func tearDownWithError() throws {
        try? clearTestDeviceId()
        try super.tearDownWithError()
    }

    private func clearTestDeviceId() throws {
        do {
            try KeychainStore.clear(.deviceId)
        } catch {
            // Ignore — test isolation
        }
    }

    // MARK: - Device ID Tests

    func testDeviceIdIsGeneratedAndPersisted() async throws {
        // Given: fresh state
        let id = TimerSyncManager.shared.deviceId

        // Then: deviceId should exist and not be empty
        XCTAssertFalse(id.isEmpty, "deviceId should not be empty")
    }

    func testDeviceIdPersistsAfterConfigure() async throws {
        // Given: TimerSyncManager instance
        let id1 = TimerSyncManager.shared.deviceId

        // When: configure timer
        TimerSyncManager.shared.configure(with: mockTimer)

        // Then: deviceId should be the same
        let id2 = TimerSyncManager.shared.deviceId
        XCTAssertEqual(id1, id2, "deviceId should persist after configure")
    }

    // MARK: - Timer Configuration Tests

    func testTimerConfiguration() async {
        // When: Timer is configured
        TimerSyncManager.shared.configure(with: mockTimer)

        // Then: Should store the timer reference
        let timer = TimerSyncManager.shared.getTimer()
        XCTAssertNotNil(timer)
    }

    func testGetTimerReturnsConfiguredTimer() async {
        // When: Timer is configured
        TimerSyncManager.shared.configure(with: mockTimer)

        // Then: getTimer should return the mock timer
        let timer = TimerSyncManager.shared.getTimer() as? PomodoroTimer
        XCTAssertNotNil(timer)
        XCTAssertTrue(timer === mockTimer)
    }

    // MARK: - Sync State Tests

    func testIsSyncingInitialValue() async {
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
