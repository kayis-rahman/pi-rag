import XCTest
@testable import Synapse

@MainActor
final class PomodoroTimerSessionTests: XCTestCase {

    private var timer: PomodoroTimer!

    override func setUpWithError() throws {
        try super.setUpWithError()
        timer = PomodoroTimer()
    }

    override func tearDownWithError() throws {
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
}
