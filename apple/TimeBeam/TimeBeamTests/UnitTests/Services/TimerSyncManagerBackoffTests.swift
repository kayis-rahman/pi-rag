//
//  TimerSyncManagerBackoffTests.swift
//  TimeBeamTests
//
//  Unit tests for TimerSyncManager exponential backoff (SYNC-04)
//

import XCTest
@testable import TimeBeam

final class TimerSyncManagerBackoffTests: XCTestCase {

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
        } catch {
            // Ignore — test isolation
        }
    }

    // MARK: - Exponential Backoff Interval Tests

    func test_firstFailure_backoff30s() {
        XCTFail("not implemented — will be satisfied by Plan 02/03")
    }

    func test_secondFailure_backoff60s() {
        XCTFail("not implemented — will be satisfied by Plan 02/03")
    }

    func test_thirdFailure_backoff120s() {
        XCTFail("not implemented — will be satisfied by Plan 02/03")
    }

    func test_fourthFailure_capped300s() {
        XCTFail("not implemented — will be satisfied by Plan 02/03")
    }

    func test_successResetsBackoff() {
        XCTFail("not implemented — will be satisfied by Plan 02/03")
    }
}
