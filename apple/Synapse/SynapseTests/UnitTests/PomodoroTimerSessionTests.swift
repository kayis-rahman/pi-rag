import XCTest
@testable import Synapse

@MainActor
final class PomodoroTimerSessionTests: XCTestCase {

    private var timer: PomodoroTimer!

    override func setUpWithError() throws {
        try super.setUpWithError()
        FocusTimerPersistence.clear()
        NotificationManager.shared = RecordingNotificationManager()
        timer = PomodoroTimer()
    }

    override func tearDownWithError() throws {
        FocusTimerPersistence.clear()
        NotificationManager.resetShared()
        timer = nil
        try super.tearDownWithError()
    }

    // MARK: - Phase Transitions

    func testAdvanceFromWorkToBreak() async {
        timer.shortBreaksCompleted = 0
        timer.phase = .work
        timer.advance()

        XCTAssertEqual(timer.phase, .break)
        XCTAssertEqual(timer.remainingSeconds, timer.breakDuration)
        XCTAssertEqual(timer.shortBreaksCompleted, 1)
    }

    func testAdvanceFromBreakToWork() async {
        timer.phase = .break
        timer.advance()

        XCTAssertEqual(timer.phase, .work)
        XCTAssertEqual(timer.remainingSeconds, timer.workDuration)
    }

    func testAdvanceFromLongBreakToWork() async {
        timer.phase = .longBreak
        timer.advance()

        XCTAssertEqual(timer.phase, .work)
        XCTAssertEqual(timer.remainingSeconds, timer.workDuration)
        XCTAssertEqual(timer.shortBreaksCompleted, 0)
    }

    // MARK: - onSessionCompleted Callback

    func testOnSessionCompletedCallbackFires() async {
        var completedPhase: Phase? = nil
        var completedDuration: Int = 0

        timer.onSessionCompleted = { phase, duration in
            completedPhase = phase
            completedDuration = duration
        }
        timer.phase = .work
        timer.advance()

        XCTAssertEqual(completedPhase, .work)
        XCTAssertEqual(completedDuration, timer.workDuration)
    }

    // MARK: - Auto-Start Next Session

    func testAutoStartNextSessionDefaultIsFalse() async {
        XCTAssertFalse(timer.autoStartNextSession)
    }

    func testAutoStartNextSessionAdvancesToBreak() async {
        timer.autoStartNextSession = true
        timer.phase = .work

        timer.advance()

        XCTAssertEqual(timer.phase, .break)
    }

    // MARK: - Focus Session Edge Cases

    func testSessionCanStartWithoutTask() {
        XCTAssertNil(timer.currentTaskId)

        timer.start()

        XCTAssertTrue(timer.isRunning)
        XCTAssertNil(timer.currentTaskId, "A task must remain optional for generic focus sessions")
        timer.pause()
    }

    func testSessionRetainsSelectedTaskWhileRunning() {
        let taskID = UUID()
        timer.currentTaskId = taskID

        timer.start()
        timer.pause()

        XCTAssertEqual(timer.currentTaskId, taskID)
    }

    func testResetClearsTaskAssociationAndRunningState() {
        timer.currentTaskId = UUID()
        timer.start()

        timer.reset()

        XCTAssertNil(timer.currentTaskId)
        XCTAssertFalse(timer.isRunning)
        XCTAssertEqual(timer.remainingSeconds, timer.workDuration)
    }

    func testStartingTwiceDoesNotReplaceOriginalStartTimestamp() {
        timer.start()
        let firstStart = timer.startTimestamp

        timer.start()

        XCTAssertEqual(timer.startTimestamp, firstStart)
        timer.pause()
    }

    func testStartingCreatesPersistableActiveSessionSnapshot() throws {
        let taskID = UUID()
        timer.currentTaskId = taskID
        timer.currentTaskTitleSnapshot = "Draft test plan"

        timer.start()
        let snapshot = timer.snapshot

        XCTAssertNotNil(snapshot.activeSessionId)
        XCTAssertEqual(snapshot.currentTaskId, taskID)
        XCTAssertEqual(snapshot.taskTitleSnapshot, "Draft test plan")
        XCTAssertTrue(snapshot.isRunning)
        XCTAssertNotNil(snapshot.endAt)
        timer.pause()
    }

    func testRestoringRunningSnapshotReconcilesElapsedTime() {
        let sessionID = UUID()
        let taskID = UUID()
        let savedAt = Date(timeIntervalSince1970: 10_000)
        FocusTimerPersistence.save(FocusTimerSnapshot(
            activeSessionId: sessionID,
            phase: .work,
            remainingSeconds: 10,
            isRunning: true,
            shortBreaksCompleted: 0,
            autoStartNextSession: false,
            currentTaskId: taskID,
            taskTitleSnapshot: "Restore this task",
            sessionStartedAt: savedAt,
            accumulatedElapsedSeconds: 0,
            runStartedAt: savedAt,
            lastReconciledAt: savedAt,
            endAt: savedAt.addingTimeInterval(10),
            savedAt: savedAt
        ))

        let restored = PomodoroTimer(workDuration: 10, breakDuration: 5)
        restored.restorePersistedState(now: savedAt.addingTimeInterval(3))

        XCTAssertTrue(restored.isRunning)
        XCTAssertEqual(restored.activeSessionId, sessionID)
        XCTAssertEqual(restored.currentTaskId, taskID)
        XCTAssertEqual(restored.remainingSeconds, 7)
        XCTAssertEqual(restored.accumulatedElapsedSeconds, 3)
        restored.pause()
    }

    func testExpiredRestoredSnapshotCompletesOnceAndLogsTaskAssociation() {
        let sessionID = UUID()
        let taskID = UUID()
        let savedAt = Date(timeIntervalSince1970: 20_000)
        var completed: SessionRecord?
        FocusTimerPersistence.save(FocusTimerSnapshot(
            activeSessionId: sessionID,
            phase: .work,
            remainingSeconds: 1,
            isRunning: true,
            shortBreaksCompleted: 0,
            autoStartNextSession: false,
            currentTaskId: taskID,
            taskTitleSnapshot: "Finish tests",
            sessionStartedAt: savedAt,
            accumulatedElapsedSeconds: 0,
            runStartedAt: savedAt,
            lastReconciledAt: savedAt,
            endAt: savedAt.addingTimeInterval(1),
            savedAt: savedAt
        ))

        let restored = PomodoroTimer(workDuration: 1, breakDuration: 5)
        restored.onFocusSessionCompleted = { completed = $0 }
        restored.restorePersistedState(now: savedAt.addingTimeInterval(2))

        XCTAssertFalse(restored.isRunning)
        XCTAssertEqual(restored.phase, .break)
        XCTAssertEqual(completed?.id, sessionID)
        XCTAssertEqual(completed?.taskId, taskID)
        XCTAssertEqual(completed?.taskTitleSnapshot, "Finish tests")
        XCTAssertEqual(completed?.duration, 2)
    }

    func testStartingSchedulesAndPausingCancelsCompletionNotification() {
        let notifications = NotificationManager.shared as? RecordingNotificationManager

        timer.start()
        XCTAssertEqual(notifications?.scheduledCount, 1)
        XCTAssertEqual(notifications?.scheduledPhase, "work")
        XCTAssertNotNil(notifications?.scheduledAt)

        timer.pause()
        XCTAssertEqual(notifications?.cancelledCount, 1)
    }
}

private final class RecordingNotificationManager: NotificationManager {
    var scheduledCount = 0
    var cancelledCount = 0
    var scheduledPhase: String?
    var scheduledAt: Date?

    override func scheduleSessionDoneNotification(phase: String, taskTitle: String?, at date: Date) {
        scheduledCount += 1
        scheduledPhase = phase
        scheduledAt = date
    }

    override func cancelSessionDoneNotification() {
        cancelledCount += 1
    }
}
