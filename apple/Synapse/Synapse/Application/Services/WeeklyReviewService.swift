import Foundation

/// Creates the structured review used by both the in-app flow and App Intents.
@MainActor
final class WeeklyReviewService {
    static let shared = WeeklyReviewService()

    private let steps: [(title: String, instructions: String, kind: WeeklyReviewStepKind)] = [
        ("Collect loose ends", "Empty your physical and digital inboxes.", .collect),
        ("Process your Inbox", "Clarify each item and choose the next action.", .process),
        ("Review stale items", "Decide what to do with old Someday / Maybe and Waiting For items.", .stale),
        ("Review projects", "Make sure every active project has a next action.", .organize),
        ("Review waiting-for", "Follow up on anything that needs a nudge.", .review),
        ("Look ahead", "Choose what deserves attention next week.", .plan)
    ]

    nonisolated static let staleAfterDays = 30

    func makeWeeklyReview(now: Date = .now, calendar: Calendar = .current) -> WeeklyReview {
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? now
        let review = WeeklyReview(weekStart: weekStart, weekEnd: weekEnd)
        review.checklistItems = steps.enumerated().map { index, step in
            WeeklyReviewItem(
                title: step.title,
                instructions: step.instructions,
                kind: step.kind,
                sortOrder: index
            )
        }
        review.lastSavedAt = now
        review.status = .inProgress
        return review
    }

    func resumeReview(from reviews: [WeeklyReview]) -> WeeklyReview? {
        reviews.filter { $0.status == .inProgress }
            .sorted { $0.lastSavedAt > $1.lastSavedAt }
            .first
    }

    func staleTasks(_ tasks: [TaskItem], now: Date = .now, thresholdDays: Int = staleAfterDays, calendar: Calendar = .current) -> [TaskItem] {
        guard let threshold = calendar.date(byAdding: .day, value: -thresholdDays, to: now) else { return [] }
        return tasks.filter {
            ($0.status == .somedayMaybe || $0.status == .waitingFor) && $0.updatedAt < threshold
        }
    }

    func prepareStaleItems(_ tasks: [TaskItem], for review: WeeklyReview, now: Date = .now) {
        review.staleTaskIDs = staleTasks(tasks, now: now).map { $0.id.uuidString }
        review.lastSavedAt = now
    }

    func saveStep(_ review: WeeklyReview, step: Int, skipped: Bool, now: Date = .now) {
        guard let item = review.checklistItems?.first(where: { $0.sortOrder == step }) else { return }
        if skipped { item.markSkipped(at: now) } else { item.markComplete(at: now) }
        let items = review.checklistItems ?? []
        review.completedStepCount = items.filter { $0.isComplete }.count
        review.skippedStepCount = items.filter(\.isSkipped).count
        review.currentStep = items.first(where: { !$0.isComplete && !$0.isSkipped })?.sortOrder ?? items.count
        review.isPartial = review.skippedStepCount > 0
        review.lastSavedAt = now
        if review.currentStep >= items.count {
            review.status = review.isPartial ? .partial : .completed
        }
    }

    func decide(_ decision: WeeklyReviewStaleDecision, for task: TaskItem, review: WeeklyReview, now: Date = .now) {
        switch decision {
        case .promote: task.status = .nextAction
        case .keep: break
        case .delete: task.status = .cancelled
        }
        if let item = review.checklistItems?.first(where: { $0.kind == .stale }) {
            item.staleDecision = decision
        }
        review.staleTaskIDs.removeAll { $0 == task.id.uuidString }
        review.lastSavedAt = now
    }

    func projectsNeedingNextAction(_ projects: [Project]) -> [Project] {
        projects.filter { !$0.isArchived && $0.status == .active && !($0.tasks ?? []).contains { $0.status == .nextAction } }
    }

    func batches<T>(_ items: [T], size: Int = 25) -> [[T]] {
        guard size > 0 else { return [] }
        return stride(from: 0, to: items.count, by: size).map { start in
            Array(items[start..<min(start + size, items.count)])
        }
    }

    func canComplete(_ project: Project) -> Bool {
        !(project.tasks ?? []).contains { $0.status == .nextAction || $0.status == .waitingFor }
    }

    func reviewStreak(_ reviews: [WeeklyReview], calendar: Calendar = .current) -> Int {
        let completed = reviews.filter { $0.status == .completed || $0.status == .partial }
            .sorted { $0.weekStart > $1.weekStart }
        guard let first = completed.first else { return 0 }
        var streak = 1
        var expected = first.weekStart
        for review in completed.dropFirst() {
            guard let prior = calendar.date(byAdding: .day, value: -7, to: expected), calendar.isDate(review.weekStart, inSameDayAs: prior) else { break }
            streak += 1
            expected = review.weekStart
        }
        return streak
    }

    func finish(_ review: WeeklyReview, reviews: [WeeklyReview], now: Date = .now, calendar: Calendar = .current) {
        review.status = review.isPartial ? .partial : .completed
        review.streakAtCompletion = reviewStreak(reviews + [review], calendar: calendar)
        review.completedAt = now
        review.lastSavedAt = now
    }
}
