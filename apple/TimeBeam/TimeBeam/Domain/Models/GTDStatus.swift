import Foundation

enum GTDStatus: String, Codable, CaseIterable, Sendable {
    case inbox
    case nextAction
    case waitingFor
    case somedayMaybe
    case completed
    case dropped

    var displayName: String {
        switch self {
        case .inbox: "Inbox"
        case .nextAction: "Next Action"
        case .waitingFor: "Waiting For"
        case .somedayMaybe: "Someday / Maybe"
        case .completed: "Completed"
        case .dropped: "Dropped"
        }
    }
}
