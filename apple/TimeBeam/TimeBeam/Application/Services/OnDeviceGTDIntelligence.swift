import Foundation

#if os(iOS) || os(macOS)
#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26, macOS 26, *)
@Generable
struct GTDTriageSuggestion {
    @Guide(description: "One of inbox, nextAction, waitingFor, somedayMaybe, completed, or dropped")
    var status: String
    @Guide(description: "A short explanation for the suggested GTD classification")
    var rationale: String
    var projectTitle: String?
    var areaTags: [String]
}

/// On-device assistance for GTD workflows. It never sends task text off-device.
@available(iOS 26, macOS 26, *)
final class OnDeviceGTDIntelligence {
    private let model = SystemLanguageModel.default

    var isAvailable: Bool { model.isAvailable }

    func triage(_ task: GTDTask) async throws -> GTDTriageSuggestion {
        let session = LanguageModelSession(instructions: """
            You are a GTD assistant. Classify captures conservatively. Never invent a due date.
            Only suggest a next action when the text describes a concrete physical or visible action.
            """)
        let response = try await session.respond(generating: GTDTriageSuggestion.self) {
            """
            Classify this capture using GTD.
            Title: \(task.title)
            Notes: \(task.notes)
            Existing tags: \(task.tags.joined(separator: ", "))
            """
        }
        return response.content
    }

    func dailyBriefing(tasks: [GTDTask], date: Date = Date()) async throws -> String {
        let session = LanguageModelSession(instructions: "Create a concise, calm daily GTD briefing.")
        let taskText = tasks.map { "- [\($0.status.displayName)] \($0.title)" }.joined(separator: "\n")
        let response = try await session.respond {
            "Date: \(date.formatted(date: .complete, time: .omitted))\nTasks:\n\(taskText)"
        }
        return response.content
    }

    func weeklyReviewPrompt(for review: WeeklyReview) async throws -> String {
        let session = LanguageModelSession(instructions: "Guide a GTD weekly review with one reflective prompt at a time.")
        let response = try await session.respond {
            "The review is on step \(review.currentStep). Ask the next useful question without changing data."
        }
        return response.content
    }
}
#endif
#endif
