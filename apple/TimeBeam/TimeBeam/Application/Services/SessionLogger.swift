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
        guard let cfg = ApiClient.Configuration.fromInfoPlist() else { return }
        let api = ApiClient(configuration: cfg)
        do {
            try await api.postSession(record, accessToken: tokenString)
        } catch {
            // Optionally: Queue for retry or handle upload failure here
        }
    }

    func importSessionsFromBackend() async {
        guard let tokenString = try? KeychainStore.loadString(.accessToken), !tokenString.isEmpty else {
            return
        }
        guard let cfg = ApiClient.Configuration.fromInfoPlist() else { return }
        let api = ApiClient(configuration: cfg)
        do {
            let remoteSessions = try await api.fetchSessions(accessToken: tokenString)
            let mapped = remoteSessions.map { payload in
                SessionRecord(
                    id: payload.id,
                    startedAt: payload.startedAt,
                    duration: payload.duration,
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

