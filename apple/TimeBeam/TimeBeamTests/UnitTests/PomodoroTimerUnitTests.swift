//  PomodoroTimerUnitTests.swift
//  TimeBeamTests
//
//  Created by TimeBeam Team
//  Unit tests for PomodoroTimer timestamp-based sync

import XCTest
@testable import TimeBeam

final class PomodoroTimerUnitTests: XCTestCase {

    private var timer: PomodoroTimer!

    override func setUp() {
        super.setUp()
        timer = PomodoroTimer()
    }

    override func tearDown() {
        timer = nil
        super.tearDown()
    }

    func testStartSetsTimestamps() {
        // Given
        let before = Date().timeIntervalSince1970

        // When
        timer.start()

        // Then
        XCTAssertNotNil(timer.startTimestamp)
        XCTAssertNil(timer.pauseTimestamp)
        XCTAssertGreaterThan(timer.startTimestamp!, before)
        XCTAssertGreaterThan(timer.lastModifiedTimestamp, before)
    }

    func testPauseSetsTimestamps() {
        // Given
        timer.start()

        // When
        let beforePause = Date().timeIntervalSince1970
        timer.pause()

        // Then
        XCTAssertNotNil(timer.pauseTimestamp)
        XCTAssertGreaterThan(timer.pauseTimestamp!, beforePause)
        XCTAssertGreaterThan(timer.lastModifiedTimestamp, beforePause)
    }

    func testPauseIgnoreWithin2Seconds() {
        // Given
        timer.startFromSync()

        // When
        let beforePause = Date()
        // Wait less than 2 seconds
        Thread.sleep(forTimeInterval: 0.5)
        timer.pause()

        // Then
        // Pause should be ignored, timer still running
        XCTAssertTrue(timer.isRunning)
        XCTAssertNil(timer.pauseTimestamp)
    }

    func testPauseExecuteAfter2Seconds() {
        // Given
        timer.startFromSync()

        // When
        // Wait more than 2 seconds
        Thread.sleep(forTimeInterval: 2.5)
        timer.pause()

        // Then
        XCTAssertFalse(timer.isRunning)
        XCTAssertNotNil(timer.pauseTimestamp)
    }

    func testRemainingSecondsDouble() {
        // Given
        timer.start()

        // When
        timer.remainingSeconds = 1234.5

        // Then
        XCTAssertEqual(timer.remainingSeconds, 1234.5)
    }

    func testProgressCalculation() {
        // Given
        timer.remainingSeconds = 750 // Half of 1500

        // When
        let progress = timer.progress

        // Then
        XCTAssertEqual(progress, 0.5, accuracy: 0.01)
    }
}