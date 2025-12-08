import Foundation

enum Phase: String, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    case work = "work"
    case `break` = "short_break"
    case longBreak = "long_break"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .work: return "Work"
        case .break: return "Break"
        case .longBreak: return "Long Break"
        }
    }
}
