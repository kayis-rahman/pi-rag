import Foundation

// MARK: - Validation Errors



public enum TaskValidationError: LocalizedError {

    case emptyTitle

    case titleTooLong

    case descriptionTooLong



    public var errorDescription: String? {

        switch self {

        case .emptyTitle:

            return "Task title cannot be empty"

        case .titleTooLong:

            return "Task title cannot exceed 255 characters"

        case .descriptionTooLong:

            return "Task description cannot exceed 1000 characters"

        }

    }

}



// MARK: - Task Filter
