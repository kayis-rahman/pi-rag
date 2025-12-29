//
//  ServerTimeManager.swift
//  TimeBeam
//
//  Manages server-based UTC time synchronization
//  Caches server UTC time on app startup for consistent timestamps
//

import Foundation

@MainActor
class ServerTimeManager {
    static let shared = ServerTimeManager()

    private var cachedServerTime: TimeInterval?
    private var cacheTimestamp: Date?
    private let cacheValidity: TimeInterval = 300 // 5 minutes

    private init() {}

    // MARK: - Public API

    /// Fetch and cache server UTC time on app startup with retry logic
    func initializeServerTime() async {
        for attempt in 1...3 {
            do {
                let serverTime = try await fetchServerTime()
                cachedServerTime = serverTime
                cacheTimestamp = Date()
                print("✅ SERVER_TIME: Cached UTC time from server: \(serverTime)")
                return
            } catch {
                print("⚠️ SERVER_TIME: Attempt \(attempt) failed to fetch server time: \(error.localizedDescription)")
                if attempt < 3 {
                    try? await Task.sleep(nanoseconds: UInt64(1 * 1_000_000_000)) // Wait 1 second
                }
            }
        }

        // All attempts failed, use device time as fallback
        print("⚠️ SERVER_TIME: All attempts failed, using device time as fallback")
        cachedServerTime = Date().timeIntervalSince1970
    }

    /// Get accurate server UTC timestamp, adjusted for elapsed time
    func getServerTimestamp() -> TimeInterval {
        if let cached = cachedServerTime,
           let cacheTime = cacheTimestamp,
           Date().timeIntervalSince(cacheTime) < cacheValidity {
            // Adjust for elapsed time since cache
            let elapsed = Date().timeIntervalSince(cacheTime)
            return cached + elapsed
        }

        // Fallback to device time if cache expired or unavailable
        print("⚠️ SERVER_TIME: Cache expired or unavailable, using device time")
        return Date().timeIntervalSince1970
    }

    // MARK: - Private Methods

    private func fetchServerTime() async throws -> TimeInterval {
        // Use hardcoded URL for now - same as configured in Info.plist
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