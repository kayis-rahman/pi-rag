import Foundation
import SwiftData

enum WeeklyReviewStatus: String, Codable, CaseIterable, Sendable {
    case notStarted
    case inProgress
    case completed
}

enum WeeklyReviewStepKind: String, Codable, CaseIterable, Sendable {
    case collect
    case process
    case organize
    case review
    case plan
}

/// A resumable weekly review workflow.
@Model
final class WeeklyReview {
    var id: UUID = UUID()
    var weekStart: Date = Date()
    var weekEnd: Date = Date()
    var startedAt: Date?
    var completedAt: Date?
    var statusRawValue: String = WeeklyReviewStatus.notStarted.rawValue
    var currentStep: Int = 0

    @Relationship(deleteRule: .nullify, inverse: \WeeklyReviewItem.review)
    var checklistItems: [WeeklyReviewItem] = []

    var status: WeeklyReviewStatus {
        get { WeeklyReviewStatus(rawValue: statusRawValue) ?? .notStarted }
        set {
            statusRawValue = newValue.rawValue
            if newValue == .inProgress {
                startedAt = startedAt ?? Date()
            } else if newValue == .completed {
                completedAt = completedAt ?? Date()
            }
        }
    }

    init(weekStart: Date, weekEnd: Date) {
        self.weekStart = weekStart
        self.weekEnd = weekEnd
    }
}

@Model
final class WeeklyReviewItem {
    var id: UUID = UUID()
    var title: String = ""
    var instructions: String = ""
    var kindRawValue: String = WeeklyReviewStepKind.collect.rawValue
    var sortOrder: Int = 0
    var isComplete: Bool = false
    var completedAt: Date?

    var review: WeeklyReview?

    var kind: WeeklyReviewStepKind {
        get { WeeklyReviewStepKind(rawValue: kindRawValue) ?? .collect }
        set { kindRawValue = newValue.rawValue }
    }

    init(
        title: String,
        instructions: String = "",
        kind: WeeklyReviewStepKind,
        sortOrder: Int
    ) {
        self.title = title
        self.instructions = instructions
        self.kindRawValue = kind.rawValue
        self.sortOrder = sortOrder
    }

    func markComplete(at date: Date = Date()) {
        isComplete = true
        completedAt = date
    }
}
