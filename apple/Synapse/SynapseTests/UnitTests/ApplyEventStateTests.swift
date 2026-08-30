import XCTest
@testable import Synapse

@MainActor
final class ApplyEventStateTests: XCTestCase {

    var sut: TimerSyncManager!
    var mockTimer: PomodoroTimer!

    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = TimerSyncManager.shared
        mockTimer = PomodoroTimer()
        mockTimer.setLastModifiedTimestamp(2000.0)
        sut.configure(with: mockTimer)
    }

    // Test 1: applyEventState with push timestamp <= local lastModifiedTimestamp skips apply
    func test_applyEventState_skipWhenPushTimestampIsStale() async {
        let userInfo: [AnyHashable: Any] = [
            "phase": "work",
            "remainingSeconds": 1500,
            "isRunning": true,
            "workDuration": 1500,
            "breakDuration": 300,
            "longBreakDuration": 900,
            "lastModifiedTimestamp": 1500.0, // Older than local 2000.0
            "autoStartNextSession": true,
            "shortBreaksCompleted": 0,
            "startTimestamp": 1000.0,
            "pauseTimestamp": nil
        ]

        let initialPhase = mockTimer.phase
        let initialRemaining = mockTimer.remainingSeconds

        sut.applyEventState(from: userInfo)

        // State should not change because push timestamp is stale
        XCTAssertEqual(mockTimer.phase, initialPhase)
        XCTAssertEqual(mockTimer.remainingSeconds, initialRemaining)
    }

    // Test 2: applyEventState with push timestamp > local lastModifiedTimestamp applies state
    func test_applyEventState_applyWhenPushTimestampIsNewer() async {
        let userInfo: [AnyHashable: Any] = [
            "phase": "short_break",
            "remainingSeconds": 250,
            "isRunning": false,
            "workDuration": 1500,
            "breakDuration": 300,
            "longBreakDuration": 900,
            "lastModifiedTimestamp": 3000.0, // Newer than local 2000.0
            "autoStartNextSession": false,
            "shortBreaksCompleted": 1,
            "startTimestamp": 2000.0,
            "pauseTimestamp": 2500.0
        ]

        sut.applyEventState(from: userInfo)

        // State should change because push timestamp is newer
        XCTAssertEqual(mockTimer.phase, .break)
        XCTAssertEqual(mockTimer.remainingSeconds, 250)
        XCTAssertEqual(mockTimer.isRunning, false)
        XCTAssertEqual(mockTimer.lastModifiedTimestamp, 3000.0)
    }

    // Test 3: applyEventState reads autoStartNextSession from userInfo (not timer fallback)
    func test_applyEventState_readsAutoStartNextSessionFromPayload() async {
        let userInfo: [AnyHashable: Any] = [
            "phase": "work",
            "remainingSeconds": 1500,
            "isRunning": true,
            "workDuration": 1500,
            "breakDuration": 300,
            "longBreakDuration": 900,
            "lastModifiedTimestamp": 3000.0, // Newer than local 2000.0
            "autoStartNextSession": true, // Explicitly from payload
            "shortBreaksCompleted": 2,
            "startTimestamp": 1000.0,
            "pauseTimestamp": nil
        ]

        mockTimer.autoStartNextSession = false // Local value is false

        sut.applyEventState(from: userInfo)

        // Should use payload value (true), not local fallback (false)
        XCTAssertEqual(mockTimer.autoStartNextSession, true)
    }

    // Test 4: applyEventState reads shortBreaksCompleted from userInfo (not timer fallback)
    func test_applyEventState_readsShortBreaksCompletedFromPayload() async {
        let userInfo: [AnyHashable: Any] = [
            "phase": "long_break",
            "remainingSeconds": 850,
            "isRunning": false,
            "workDuration": 1500,
            "breakDuration": 300,
            "longBreakDuration": 900,
            "lastModifiedTimestamp": 3000.0, // Newer than local 2000.0
            "autoStartNextSession": true,
            "shortBreaksCompleted": 4, // Explicitly from payload
            "startTimestamp": nil,
            "pauseTimestamp": nil
        ]

        mockTimer.shortBreaksCompleted = 1 // Local value is 1

        sut.applyEventState(from: userInfo)

        // Should use payload value (4), not local fallback (1)
        XCTAssertEqual(mockTimer.shortBreaksCompleted, 4)
    }

    // Test 5: applyEventState with equal timestamps skips apply (per D-01)
    func test_applyEventState_skipWhenTimestampsAreEqual() async {
        mockTimer.setLastModifiedTimestamp(2000.0)

        let userInfo: [AnyHashable: Any] = [
            "phase": "work",
            "remainingSeconds": 500,
            "isRunning": true,
            "workDuration": 1500,
            "breakDuration": 300,
            "longBreakDuration": 900,
            "lastModifiedTimestamp": 2000.0, // Equal to local
            "autoStartNextSession": true,
            "shortBreaksCompleted": 0,
            "startTimestamp": 1000.0,
            "pauseTimestamp": nil
        ]

        let initialRemaining = mockTimer.remainingSeconds

        sut.applyEventState(from: userInfo)

        // State should not change because timestamps are equal
        XCTAssertEqual(mockTimer.remainingSeconds, initialRemaining)
    }

    // Test 6: applyEventState handles NSNumber types for numeric fields
    func test_applyEventState_handlesNSNumberTypes() async {
        let userInfo: [AnyHashable: Any] = [
            "phase": "work",
            "remainingSeconds": NSNumber(value: 1200), // NSNumber instead of Int
            "isRunning": NSNumber(value: true), // NSNumber instead of Bool
            "workDuration": 1500,
            "breakDuration": 300,
            "longBreakDuration": 900,
            "lastModifiedTimestamp": 3000.0,
            "autoStartNextSession": true,
            "shortBreaksCompleted": 3,
            "startTimestamp": 1000.0,
            "pauseTimestamp": nil
        ]

        sut.applyEventState(from: userInfo)

        XCTAssertEqual(mockTimer.remainingSeconds, 1200)
        XCTAssertEqual(mockTimer.isRunning, true)
    }
}
