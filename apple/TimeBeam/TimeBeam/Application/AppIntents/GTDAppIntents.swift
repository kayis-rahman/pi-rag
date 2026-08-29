import AppIntents
import SwiftData

@MainActor
struct CaptureTaskIntent: AppIntent {
    static var title: LocalizedStringResource { "Capture Task" }
    static var description = IntentDescription("Add an unprocessed item to the Synapse inbox.")
    static var openAppWhenRun: Bool { false }

    @Parameter(title: "Task")
    var title: String

    static var parameterSummary: some ParameterSummary {
        Summary("Capture \(\.$title)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let task = GTDTask(title: title)
        let context = PersistenceController.shared.mainContext
        context.insert(task)
        try context.save()
        return .result(dialog: "Captured in Inbox.")
    }
}

@MainActor
struct AddNextActionIntent: AppIntent {
    static var title: LocalizedStringResource { "Add Next Action" }
    static var description = IntentDescription("Add a concrete next action to Synapse.")
    static var openAppWhenRun: Bool { false }

    @Parameter(title: "Action")
    var title: String

    static var parameterSummary: some ParameterSummary {
        Summary("Add next action \(\.$title)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let task = GTDTask(title: title, status: .nextAction)
        let context = PersistenceController.shared.mainContext
        context.insert(task)
        try context.save()
        return .result(dialog: "Added to Next Actions.")
    }
}

@MainActor
struct StartWeeklyReviewIntent: AppIntent {
    static var title: LocalizedStringResource { "Start Weekly Review" }
    static var description = IntentDescription("Start a structured GTD weekly review in Synapse.")
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let calendar = Calendar.current
        let today = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? today
        let review = WeeklyReview(weekStart: weekStart, weekEnd: weekEnd)
        review.checklistItems = WeeklyReviewDefaults.items()
        review.status = .inProgress

        let context = PersistenceController.shared.mainContext
        context.insert(review)
        try context.save()
        return .result(dialog: "Weekly review started.")
    }
}

enum WeeklyReviewDefaults {
    static func items() -> [WeeklyReviewItem] {
        [
            WeeklyReviewItem(title: "Collect loose ends", kind: .collect, sortOrder: 0),
            WeeklyReviewItem(title: "Process Inbox", kind: .process, sortOrder: 1),
            WeeklyReviewItem(title: "Review projects and next actions", kind: .organize, sortOrder: 2),
            WeeklyReviewItem(title: "Review Waiting For and Someday / Maybe", kind: .review, sortOrder: 3),
            WeeklyReviewItem(title: "Choose priorities for the week", kind: .plan, sortOrder: 4)
        ]
    }
}

struct SynapseShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        [
            AppShortcut(intent: CaptureTaskIntent(), phrases: ["Capture a task in \(.applicationName)", "Add an inbox item in \(.applicationName)"]),
            AppShortcut(intent: AddNextActionIntent(), phrases: ["Add a next action in \(.applicationName)"]),
            AppShortcut(intent: StartWeeklyReviewIntent(), phrases: ["Start my weekly review in \(.applicationName)"])
        ]
    }
}
