import Foundation

@MainActor
public final class SessionLogger: ObservableObject {
    @Published public private(set) var records: [SessionRecord] = []

    private let storageKey = "SessionLogger.records.v1"

    public init() {
        load()
    }

    public func add(record: SessionRecord) {
        records.append(record)
        save()
    }

    public func clear() {
        records.removeAll()
        save()
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(records)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            // ignore for now
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        if let decoded = try? JSONDecoder().decode([SessionRecord].self, from: data) {
            records = decoded
        }
    }
}
