//
//  SyncFailureAlertTests.swift
//  SynapseTests
//
//  Unit tests for sync failure alert UI behavior (D-06)
//

import XCTest
@testable import Synapse

@MainActor
final class SyncFailureAlertTests: XCTestCase {

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

    // MARK: - Sync Failure Alert Visibility Tests

    func test_twoFailures_noAlert() async {
        XCTFail("not implemented — will be satisfied by Plan 02/03")
    }

    func test_threeConsecutiveFailures_triggersAlert() async {
        XCTFail("not implemented — will be satisfied by Plan 02/03")
    }

    func test_manualRetry_resetsFailureCount() async {
        XCTFail("not implemented — will be satisfied by Plan 02/03")
    }

    func test_successAfterAlert_dismissesAlert() async {
        XCTFail("not implemented — will be satisfied by Plan 02/03")
    }
}
