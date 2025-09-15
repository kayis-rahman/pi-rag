//  TimeBeamTests.swift
//  TimeBeamTests
//
//  Created by AI Assistant on 15/09/25.

import XCTest
@testable import TimeBeam

final class TimeBeamTests: XCTestCase {
    func testTimerControlFlow() async throws {
        let timer = await MainActor.run { PomodoroTimer(workDuration: 3, breakDuration: 2) }
        XCTAssertFalse(await timer.isRunning)
        XCTAssertEqual(await timer.phase, .work)
        XCTAssertEqual(await timer.remainingSeconds, 3)
        await MainActor.run { timer.start() }
        try await Task.sleep(nanoseconds: 1_200_000_000)
        let afterStartRemaining = await timer.remainingSeconds
        XCTAssertTrue(await timer.isRunning)
        XCTAssertTrue(afterStartRemaining <= 2 && afterStartRemaining >= 1)
        await MainActor.run { timer.pause() }
        let pausedRemaining = await timer.remainingSeconds
        try await Task.sleep(nanoseconds: 1_200_000_000)
        let pausedRemainingAfter = await timer.remainingSeconds
        XCTAssertFalse(await timer.isRunning)
        XCTAssertEqual(pausedRemainingAfter, pausedRemaining)
        await MainActor.run { timer.reset() }
        XCTAssertEqual(await timer.phase, .work)
        XCTAssertEqual(await timer.remainingSeconds, 3)
        XCTAssertFalse(await timer.isRunning)
    }

    func testPhaseSwitching() async throws {
        let timer = await MainActor.run { PomodoroTimer(workDuration: 1, breakDuration: 1) }
        await MainActor.run { timer.start() }
        try await Task.sleep(nanoseconds: 1_200_000_000)
        XCTAssertEqual(await timer.phase, .break)
        try await Task.sleep(nanoseconds: 1_200_000_000)
        XCTAssertEqual(await timer.phase, .work)
        await MainActor.run { timer.pause() }
    }

    func testProgressCalculation() async throws {
        let timer = await MainActor.run { PomodoroTimer(workDuration: 4, breakDuration: 2) }
        XCTAssertEqual(await timer.progress, 0)
        await MainActor.run { timer.start() }
        try await Task.sleep(nanoseconds: 1_100_000_000)
        let p1 = await timer.progress
        XCTAssertTrue(p1 > 0 && p1 < 1)
        await MainActor.run { timer.pause() }
        await MainActor.run { timer.remainingSeconds = 0 }
        let p2 = await timer.progress
        XCTAssertEqual(p2, 1)
    }

    func testResetAlwaysWorkPhase() async throws {
        let timer = await MainActor.run { PomodoroTimer(workDuration: 2, breakDuration: 2) }
        await MainActor.run { timer.start() }
        try await Task.sleep(nanoseconds: 1_200_000_000)
        XCTAssertEqual(await timer.phase, .break)
        await MainActor.run { timer.reset() }
        XCTAssertEqual(await timer.phase, .work)
        XCTAssertEqual(await timer.remainingSeconds, 2)
        XCTAssertFalse(await timer.isRunning)
    }
}
