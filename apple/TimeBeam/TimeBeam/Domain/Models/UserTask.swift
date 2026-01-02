import Foundation



public struct UserTask: Codable, Identifiable, Equatable {

    public enum Status: String, Codable {

        case todo, inProgress = "in_progress", completed



        public var displayName: String {

            switch self {

            case .todo: return "To Do"

            case .inProgress: return "In Progress"

            case .completed: return "Completed"

            }

        }



        public var isActive: Bool {

            return self == .todo || self == .inProgress

        }



        public var isCompleted: Bool {

            return self == .completed

        }

    }



    public let id: UUID

    public let userId: UUID

    public let title: String

    public let description: String?

    public let status: Status

    public let createdAt: Date

    public let updatedAt: Date



    public init(id: UUID = UUID(),

                userId: UUID,

                title: String,

                description: String? = nil,

                status: Status = .todo,

                createdAt: Date = Date(),

                updatedAt: Date = Date()) {

        self.id = id

        self.userId = userId

        self.title = title

        self.description = description

        self.status = status

        self.createdAt = createdAt

        self.updatedAt = updatedAt

    }



    // Domain methods

    public var isActive: Bool {

        return status.isActive

    }



    public var isCompleted: Bool {

        return status.isCompleted

    }



    public func withTitle(_ newTitle: String) -> UserTask {

        return UserTask(id: id, userId: userId, title: newTitle, description: description,

                        status: status, createdAt: createdAt, updatedAt: Date())

    }



    public func withDescription(_ newDescription: String?) -> UserTask {

        return UserTask(id: id, userId: userId, title: title, description: newDescription,

                       status: status, createdAt: createdAt, updatedAt: Date())

    }



    public func withStatus(_ newStatus: Status) -> UserTask {

        return UserTask(id: id, userId: userId, title: title, description: description,

                        status: newStatus, createdAt: createdAt, updatedAt: Date())

    }



    // Validation

    public func validate() throws {

        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {

            throw TaskValidationError.emptyTitle

        }

        guard title.count <= 255 else {

            throw TaskValidationError.titleTooLong

        }

        if let description = description {

            guard description.count <= 1000 else {

                throw TaskValidationError.descriptionTooLong

            }

        }

    }

}


