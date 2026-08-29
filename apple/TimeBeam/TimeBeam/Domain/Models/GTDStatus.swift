import Foundation

/// The GTD stage of a task. The raw value is persisted so the model remains
/// stable when stored locally or synchronized through CloudKit.
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
