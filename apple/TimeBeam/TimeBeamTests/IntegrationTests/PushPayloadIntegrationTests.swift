//
//  PushPayloadIntegrationTests.swift
//  TimeBeamTests
//
//  Integration tests for push payload and delta apply (SYNC-05)
//

import XCTest
@testable import TimeBeam

final class PushPayloadIntegrationTests: XCTestCase {

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

    // MARK: - Push Payload Timestamp Comparison Tests

    func test_applyEventState_withNewerTimestamp_appliesState() {
        XCTFail("not implemented — will be satisfied by Plan 02/setupApp()")
    }

    func test_applyEventState_withOlderTimestamp_skipsApply() {
        XCTFail("not implemented — will be satisfied by Plan 02/setupApp()")
    }

    // MARK: - Push Payload Field Tests

    func test_applyEventState_readsAutoStartNextSession() {
        XCTFail("not implemented — will be satisfied by Plan 02/setupApp()")
    }

    func test_applyEventState_readsShortBreaksCompleted() {
        XCTFail("not implemented — will be satisfied by Plan 02/setupApp()")
    }

    func test_pushPayload_containsAllRequiredFields() {
        XCTFail("not implemented — will be satisfied by Plan 01/02")
    }
}
