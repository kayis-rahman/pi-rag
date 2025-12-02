import Foundation

enum Phase: String, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    case work
    case `break`
    case longBreak

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .work: return "Work"
        case .break: return "Break"
        case .longBreak: return "Long Break"
        }
    }
}
