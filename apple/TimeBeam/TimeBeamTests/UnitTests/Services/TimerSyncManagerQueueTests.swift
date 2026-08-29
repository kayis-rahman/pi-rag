//
//  TimerSyncManagerQueueTests.swift
//  TimeBeamTests
//
//  Unit tests for TimerSyncManager offline action queue (SYNC-02, SYNC-03)
//

import XCTest
@testable import TimeBeam

@MainActor
final class TimerSyncManagerQueueTests: XCTestCase {

    private var mockTimer: PomodoroTimer!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockTimer = PomodoroTimer()
        try? clearTestState()
        let syncManager = TimerSyncManager.shared
        syncManager.configure(with: mockTimer)
    }

    override func tearDownWithError() throws {
        try? clearTestState()
        try super.tearDownWithError()
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

    func test_enqueueAction_addsToQueue() async {
        XCTFail("not implemented — will be satisfied by Plan 02/03")
    }

    func test_enqueueAction_persistsToKeychain() async {
        XCTFail("not implemented — will be satisfied by Plan 02/03")
    }

    func test_queue_overflow_dropsOldest() async {
        XCTFail("not implemented — will be satisfied by Plan 02/03")
    }

    // MARK: - Action Queue Drain Tests

    func test_drainActionQueue_replaysInOrder() async {
        XCTFail("not implemented — will be satisfied by Plan 02/03")
    }

    func test_drainActionQueue_requeuesOnConsecutiveFailures() async {
        XCTFail("not implemented — will be satisfied by Plan 02/03")
    }

    func test_loadActionQueue_restoresFromKeychain() async {
        XCTFail("not implemented — will be satisfied by Plan 02/03")
    }
}
