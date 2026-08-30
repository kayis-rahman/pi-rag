//
// SessionLogger.swift
// Synapse
//
// Created by Kayis Rahman on 03/11/25.
//

import Foundation
import Observation

// Domain models and infrastructure
// (Types should be available in the same module)

@MainActor
@Observable
final class SessionLogger {
    private(set) var records: [SessionRecordDto] = []

    private let storageKey = "SessionLogger.records.v1"

    init() {
        load()
    }

    func add(record: SessionRecord) {
        // Convert domain model to API DTO for API layer
        let dto = SessionRecordDto(
            id: record.id,
            startedAt: record.startedAt,
            duration: record.duration,
            kind: record.kind.rawValue
        )
        records.append(dto)
        save()
    }

    func clear() {
        records.removeAll()
        save()
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(records)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            // Handle error
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        if let decoded = try? JSONDecoder().decode([SessionRecordDto].self, from: data) {
            records = decoded
        }
    }

    // MARK: - Sync logic

    private func uploadRecord(_ dto: SessionRecordDto) async {
        guard let tokenString = try? KeychainStore.loadString(.accessToken), !tokenString.isEmpty else {
            return
        }
        guard ApiClient.Configuration.fromInfoPlist() != nil else { return }
        let api = ApiClient.shared
        do {
            try await api.postSession(dto, accessToken: tokenString)
        } catch {
            // Optionally: Queue for retry or handle upload failure here
        }
    }

    func importSessionsFromBackend() async {
        guard let tokenString = try? KeychainStore.loadString(.accessToken), !tokenString.isEmpty else {
            return
        }
        guard ApiClient.Configuration.fromInfoPlist() != nil else { return }
        let api = ApiClient.shared
        do {
             let remoteSessions = try await api.fetchSessions(accessToken: tokenString)
             // No conversion needed - API returns DTOs directly
             await MainActor.run {
                 records = remoteSessions
                 save()
             }
        } catch {
            // Handle error (network, decode, etc)
        }
    }
}
