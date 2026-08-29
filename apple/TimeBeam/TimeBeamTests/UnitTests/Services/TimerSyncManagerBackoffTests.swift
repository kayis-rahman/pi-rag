//
//  TimerSyncManagerBackoffTests.swift
//  TimeBeamTests
//
//  Unit tests for TimerSyncManager exponential backoff (SYNC-04)
//

import XCTest
@testable import TimeBeam

@MainActor
final class TimerSyncManagerBackoffTests: XCTestCase {

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
        } catch {
            // Ignore — test isolation
        }
    }

    // MARK: - Exponential Backoff Interval Tests

    func test_firstFailure_backoff30s() async {
        XCTFail("not implemented — will be satisfied by Plan 02/03")
    }

    func test_secondFailure_backoff60s() async {
        XCTFail("not implemented — will be satisfied by Plan 02/03")
    }

    func test_thirdFailure_backoff120s() async {
        XCTFail("not implemented — will be satisfied by Plan 02/03")
    }

    func test_fourthFailure_capped300s() async {
        XCTFail("not implemented — will be satisfied by Plan 02/03")
    }

    func test_successResetsBackoff() async {
        XCTFail("not implemented — will be satisfied by Plan 02/03")
    }
}
