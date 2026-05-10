//
//  SyncFailureAlertTests.swift
//  TimeBeamTests
//
//  Unit tests for sync failure alert UI behavior (D-06)
//

import XCTest
@testable import TimeBeam

final class SyncFailureAlertTests: XCTestCase {

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

    // MARK: - Sync Failure Alert Visibility Tests

    func test_twoFailures_noAlert() {
        XCTFail("not implemented — will be satisfied by Plan 02/03")
    }

    func test_threeConsecutiveFailures_triggersAlert() {
        XCTFail("not implemented — will be satisfied by Plan 02/03")
    }

    func test_manualRetry_resetsFailureCount() {
        XCTFail("not implemented — will be satisfied by Plan 02/03")
    }

    func test_successAfterAlert_dismissesAlert() {
        XCTFail("not implemented — will be satisfied by Plan 02/03")
    }
}
