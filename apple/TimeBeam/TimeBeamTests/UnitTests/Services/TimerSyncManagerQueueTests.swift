//
//  TimerSyncManagerQueueTests.swift
//  TimeBeamTests
//
//  Unit tests for TimerSyncManager offline action queue (SYNC-02, SYNC-03)
//

import XCTest
@testable import TimeBeam

final class TimerSyncManagerQueueTests: XCTestCase {

    private var mockTimer: MockPomodoroTimer!

    override func setUpWithError() throws {
        mockTimer = MockPomodoroTimer()
        try clearTestState()
        let syncManager = TimerSyncManager.shared
        syncManager.configure(with: mockTimer)
    }

    override func tearDownWithError() throws {
        try clearTestState()
    }

    private func clearTestState() throws {
        do {
            try KeychainStore.clear(.deviceId)
            try KeychainStore.clear(.actionQueue)
        } catch {
            // Ignore — test isolation
        }
    }

    // MARK: - Action Queue Enqueue Tests

    func test_enqueueAction_addsToQueue() {
        XCTFail("not implemented — will be satisfied by Plan 02/03")
    }

    func test_enqueueAction_persistsToKeychain() {
        XCTFail("not implemented — will be satisfied by Plan 02/03")
    }

    func test_queue_overflow_dropsOldest() {
        XCTFail("not implemented — will be satisfied by Plan 02/03")
    }

    // MARK: - Action Queue Drain Tests

    func test_drainActionQueue_replaysInOrder() {
        XCTFail("not implemented — will be satisfied by Plan 02/03")
    }

    func test_drainActionQueue_requeuesOnConsecutiveFailures() {
        XCTFail("not implemented — will be satisfied by Plan 02/03")
    }

    func test_loadActionQueue_restoresFromKeychain() {
        XCTFail("not implemented — will be satisfied by Plan 02/03")
    }
}
