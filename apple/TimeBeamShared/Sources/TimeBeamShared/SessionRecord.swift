import Foundation

public struct SessionRecord: Codable, Identifiable, Equatable {
    public enum Kind: String, Codable { case work, shortBreak, longBreak }

    public let id: UUID
    public let startedAt: Date
    public let duration: TimeInterval
    public let kind: Kind

    public init(id: UUID = UUID(), startedAt: Date, duration: TimeInterval, kind: Kind) {
        self.id = id
        self.startedAt = startedAt
        self.duration = duration
        self.kind = kind
    }

    public var isProductive: Bool { kind == .work }
}
