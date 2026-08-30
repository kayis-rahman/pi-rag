import XCTest
@testable import Synapse

@MainActor
final class TimerSyncManagerActionQueueTests: XCTestCase {

    var sut: TimerSyncManager!
    var mockTimer: PomodoroTimer!

    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = TimerSyncManager.shared
        mockTimer = PomodoroTimer()
        sut.configure(with: mockTimer)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        // Clean up Keychain after tests
        try? KeychainStore.clear(.actionQueue)
    }

    // Test 1: enqueueAction adds to actionQueue array and calls persistActionQueue
    func test_enqueueAction_addsToArrayAndPersists() async throws {
        let action = QueuedTimerAction(
            action: "start",
            timestamp: 1000.0,
            phase: "work",
            remainingSeconds: 1500,
            isRunning: true,
            workDuration: 1500,
            breakDuration: 300,
            longBreakDuration: 900,
            autoStartNextSession: true,
            shortBreaksCompleted: 0
        )

        // Enqueue the action
        sut.enqueueAction(action)

        // Verify persisted to Keychain
        let loaded = try KeychainStore.load(.actionQueue)
        XCTAssertNotNil(loaded)

        let decoded = try JSONDecoder().decode([QueuedTimerAction].self, from: loaded!)
        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded[0].action, "start")
        XCTAssertEqual(decoded[0].timestamp, 1000.0)
    }

    // Test 2: persistActionQueue encodes actionQueue to JSON and saves to KeychainStore
    func test_persistActionQueue_encodeAndSave() async throws {
        let action1 = QueuedTimerAction(
            action: "start",
            timestamp: 1000.0,
            phase: "work",
            remainingSeconds: 1500,
            isRunning: true,
            workDuration: 1500,
            breakDuration: 300,
            longBreakDuration: 900,
            autoStartNextSession: true,
            shortBreaksCompleted: 0
        )

        let action2 = QueuedTimerAction(
            action: "pause",
            timestamp: 2000.0,
            phase: "work",
            remainingSeconds: 1200,
            isRunning: false,
            workDuration: 1500,
            breakDuration: 300,
            longBreakDuration: 900,
            autoStartNextSession: false,
            shortBreaksCompleted: 1
        )

        sut.enqueueAction(action1)
        sut.enqueueAction(action2)

        let loaded = try KeychainStore.load(.actionQueue)
        XCTAssertNotNil(loaded)

        let decoded = try JSONDecoder().decode([QueuedTimerAction].self, from: loaded!)
        XCTAssertEqual(decoded.count, 2)
        XCTAssertEqual(decoded[0].action, "start")
        XCTAssertEqual(decoded[1].action, "pause")
    }

    // Test 3: loadActionQueue reads from KeychainStore and returns decoded array
    func test_loadActionQueue_readsFromKeychainAndDecodes() async throws {
        let action = QueuedTimerAction(
            action: "reset",
            timestamp: 3000.0,
            phase: "long_break",
            remainingSeconds: 850,
            isRunning: false,
            workDuration: 1500,
            breakDuration: 300,
            longBreakDuration: 900,
            autoStartNextSession: true,
            shortBreaksCompleted: 4
        )

        // Manually save to Keychain
        let encoded = try JSONEncoder().encode([action])
        try KeychainStore.save(encoded, for: .actionQueue)

        // Load using the manager's method
        let loaded = sut.loadActionQueue()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].action, "reset")
        XCTAssertEqual(loaded[0].timestamp, 3000.0)
    }

    // Test 4: When actionQueue reaches maxQueueSize (50), oldest entry is dropped
    func test_enqueueAction_dropsOldestWhenExceedsMaxSize() async throws {
        // Enqueue 51 actions
        for i in 0..<51 {
            let action = QueuedTimerAction(
                action: "start",
                timestamp: Double(i),
                phase: "work",
                remainingSeconds: 1500,
                isRunning: true,
                workDuration: 1500,
                breakDuration: 300,
                longBreakDuration: 900,
                autoStartNextSession: true,
                shortBreaksCompleted: 0
            )
            sut.enqueueAction(action)
        }

        // Verify only 50 actions remain (oldest dropped)
        let loaded = try KeychainStore.load(.actionQueue)
        XCTAssertNotNil(loaded)

        let decoded = try JSONDecoder().decode([QueuedTimerAction].self, from: loaded!)
        XCTAssertEqual(decoded.count, 50)

        // Verify first action is the second one we enqueued (index 1), not index 0
        XCTAssertEqual(decoded[0].timestamp, 1.0)
        XCTAssertEqual(decoded[49].timestamp, 50.0)
    }

    // Test 5: configure() calls loadActionQueue and if network is connected, drains persisted queue
    func test_configure_loadsPersistedQueue() async throws {
        // Pre-populate Keychain with some actions
        let action = QueuedTimerAction(
            action: "advance",
            timestamp: 4000.0,
            phase: "break",
            remainingSeconds: 300,
            isRunning: false,
            workDuration: 1500,
            breakDuration: 300,
            longBreakDuration: 900,
            autoStartNextSession: false,
            shortBreaksCompleted: 1
        )

        let encoded = try JSONEncoder().encode([action])
        try KeychainStore.save(encoded, for: .actionQueue)

        // Create a fresh timer and configure (loads queue)
        let freshTimer = PomodoroTimer()
        sut.configure(with: freshTimer)

        // Verify queue was loaded (should have 1 action)
        let loaded = try KeychainStore.load(.actionQueue)
        XCTAssertNotNil(loaded)

        let decoded = try JSONDecoder().decode([QueuedTimerAction].self, from: loaded!)
        XCTAssertEqual(decoded.count, 1)
    }

    // Test 6: clearActionQueue removes persisted queue from Keychain
    func test_clearActionQueue_removesFromKeychain() async throws {
        let action = QueuedTimerAction(
            action: "start",
            timestamp: 5000.0,
            phase: "work",
            remainingSeconds: 1500,
            isRunning: true,
            workDuration: 1500,
            breakDuration: 300,
            longBreakDuration: 900,
            autoStartNextSession: true,
            shortBreaksCompleted: 0
        )

        // Enqueue action
        sut.enqueueAction(action)

        // Verify it's in Keychain
        var loaded = try KeychainStore.load(.actionQueue)
        XCTAssertNotNil(loaded)

        // Clear the queue
        sut.clearActionQueue()

        // Verify it's removed from Keychain
        loaded = try KeychainStore.load(.actionQueue)
        XCTAssertNil(loaded)
    }
}
