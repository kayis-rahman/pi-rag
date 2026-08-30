//
//  SetupAppSyncTests.swift
//  SynapseTests
//
//  Integration tests for state restoration on app relaunch (SYNC-06)
//

import XCTest
@testable import Synapse

@MainActor
final class SetupAppSyncTests: XCTestCase {

    private var mockTimer: PomodoroTimer!

    override func setUp() async throws {
        try await super.setUp()
        mockTimer = PomodoroTimer()
        try? clearTestState()
        let syncManager = TimerSyncManager.shared
        syncManager.configure(with: mockTimer)
    }

    override func tearDown() async throws {
        try? clearTestState()
        try await super.tearDown()
    }

    private func clearTestState() throws {
        do {
            try KeychainStore.clear(.deviceId)
        } catch {
            // Ignore — test isolation
        }
    }

    // MARK: - App Launch Sync Flow Tests

    func test_setupApp_restoresAuthBeforePull() {
        XCTFail("not implemented — will be satisfied by Plan 02/setupApp()")
    }

    func test_setupApp_pullsTimerStateAfterAuth() {
        XCTFail("not implemented — will be satisfied by Plan 02/setupApp()")
    }

    func test_setupApp_setsIsAppReadyLast() {
        XCTFail("not implemented — will be satisfied by Plan 02/setupApp()")
    }

    func test_appLaunch_timerStateMatchesBackend() {
        XCTFail("not implemented — will be satisfied by Plan 02/setupApp()")
    }
}
