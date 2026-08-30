//
//  ServerTimeOffsetManager.swift
//  Synapse
//
//  Calculates and caches UTC offset from server on startup
//  Uses cached offset for accurate UTC timestamp conversion
//

import Foundation

@MainActor
class ServerTimeOffsetManager {
    static let shared = ServerTimeOffsetManager()

    private var cachedOffset: TimeInterval?  // seconds difference from UTC
    private var lastCalculationTime: Date?
    private let cacheValidity: TimeInterval = 3600 // 1 hour

    private init() {}

    // MARK: - Public API

    /// Calculate and cache UTC offset on app startup
    func initializeOffset() async {
        print("🔍 OFFSET_TIME: Starting offset calculation...")
        do {
            let offset = try await calculateOffset()
            cachedOffset = offset
            lastCalculationTime = Date()
            print("✅ OFFSET_TIME: Calculated and cached UTC offset: \(offset) seconds")
        } catch {
            print("⚠️ OFFSET_TIME: Failed to calculate offset, using device timezone fallback")
            print("Error: \(error.localizedDescription)")
            // Fallback: use current timezone offset
            cachedOffset = TimeInterval(TimeZone.current.secondsFromGMT(for: Date()))
        }
    }

    /// Get accurate UTC timestamp using cached offset
    func getUTCTimestamp() -> TimeInterval {
        let deviceTime = Date().timeIntervalSince1970

        if let offset = cachedOffset,
           let calcTime = lastCalculationTime,
           Date().timeIntervalSince(calcTime) < cacheValidity {
            // Use cached offset: deviceTime - offset = UTC time
            return deviceTime - offset
        }

        // Fallback: use current timezone offset if cache expired
        print("⚠️ OFFSET_TIME: Cache expired or unavailable, using device timezone")
        let currentOffset = TimeInterval(TimeZone.current.secondsFromGMT(for: Date()))
        return deviceTime - currentOffset
    }

    // MARK: - Private Methods

    /// Calculate offset: device time - server UTC time
    private func calculateOffset() async throws -> TimeInterval {
        let serverUTC = try await fetchServerTime()
        let deviceTime = Date().timeIntervalSince1970

        // Offset = difference between device time and server UTC
        // Positive offset means device is ahead of UTC
        let offset = deviceTime - serverUTC

        print("🔍 OFFSET_TIME: Device time: \(deviceTime), Server UTC: \(serverUTC), Calculated offset: \(offset)")
        return offset
    }

    private func fetchServerTime() async throws -> TimeInterval {
        guard let url = URL(string: "http://192.168.0.173:8080/api/time") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        struct TimeResponse: Codable {
            let preciseTimestamp: TimeInterval
        }

        let timeResponse = try JSONDecoder().decode(TimeResponse.self, from: data)
        return timeResponse.preciseTimestamp
    }
}