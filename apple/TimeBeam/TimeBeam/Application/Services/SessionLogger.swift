import Foundation

//
//  SessionLogger.swift
//  TimeBeam
//
//  Created by Kayis Rahman on 03/11/25.
//

import Foundation

// Domain models and infrastructure
// (Types should be available in the same module)

@MainActor
final class SessionLogger: ObservableObject {
    @Published private(set) var records: [SessionRecord] = []

    private let storageKey = "SessionLogger.records.v1"

    init() {
        load()
    }

    func add(record: SessionRecord) {
        records.append(record)
        save()
        // _Concurrency.Task {
        //     await uploadRecord(record)
        // }
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
        if let decoded = try? JSONDecoder().decode([SessionRecord].self, from: data) {
            records = decoded
        }
    }

    // MARK: - Sync logic

    private func uploadRecord(_ record: SessionRecord) async {
        guard let tokenString = try? KeychainStore.loadString(.accessToken), !tokenString.isEmpty else {
            return
        }
        guard let cfg = Configuration.fromInfoPlist() else { return }
        let api = ApiClient(baseURL: cfg.baseURL)
        do {
            // Convert SessionRecord to SessionRecordDto for API call
            let sessionDto = ApiClient.SessionRecordDto(
                id: record.id,
                startedAt: record.startedAt,
                duration: record.duration,
                kind: record.kind.rawValue
            )
            try await api.postSession(sessionDto, accessToken: tokenString)
        } catch {
            // Optionally: Queue for retry or handle upload failure here
        }
    }

    func importSessionsFromBackend() async {
        guard let tokenString = try? KeychainStore.loadString(.accessToken), !tokenString.isEmpty else {
            return
        }
        guard let cfg = Configuration.fromInfoPlist() else { return }
        let api = ApiClient(baseURL: cfg.baseURL)
        do {
            let remoteSessions = try await api.fetchSessions(accessToken: tokenString)
            let mapped = remoteSessions.map { payload in
                SessionRecord(
                    id: payload.id,
                    startedAt: payload.startedAt,
                    duration: Double(payload.durationSeconds),
                    kind: SessionRecord.Kind(rawValue: payload.kind) ?? .work
                )
            }
            await MainActor.run {
                self.records = mapped
                self.save()
            }
        } catch {
            // Handle error (network, decode, etc)
        }
    }
}

