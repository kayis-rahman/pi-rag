import Foundation

@MainActor
final class TaskService: ObservableObject {
    @Published private(set) var tasks: [UserTask] = []
    @Published private(set) var activeTasks: [UserTask] = []

    private let apiClient: ApiClientProtocol
    private let keychainStore: KeychainStoreProtocol

    init(apiClient: ApiClientProtocol? = nil,
         keychainStore: KeychainStoreProtocol = KeychainStore()) {
        if let apiClient = apiClient {
            self.apiClient = apiClient
        } else if let config = ApiClient.Configuration.fromInfoPlist() {
            self.apiClient = ApiClient(configuration: config)
        } else {
            // Fallback for tests or when Info.plist is not available
            let fallbackURL = URL(string: "http://localhost:8080")!
            self.apiClient = ApiClient(configuration: ApiClient.Configuration(baseURL: fallbackURL))
        }
        self.keychainStore = keychainStore
        loadCachedTasks()
    }

    // MARK: - Task Creation

    func createTask(title: String, description: String? = nil) async throws -> UserTask {
        // Validate input
        try validateTaskInput(title: title, description: description)

        let request = APIRequest.createTask(title: title, description: description)
        let response: ApiClient.TaskDto = try await apiClient.performRequest(request)

        let task = UserTask(
            id: response.id,
            userId: response.userId,
            title: response.title,
            description: response.description,
            status: UserTask.Status(rawValue: response.status) ?? .todo,
            createdAt: response.createdAt,
            updatedAt: response.updatedAt
        )

        // Update local cache
        tasks.append(task)
        updateActiveTasks()
        saveCachedTasks()

        return task
    }

    // MARK: - Task Retrieval

    func fetchTasks(status: ApiTaskStatus? = nil) async throws -> [UserTask] {
        let request = APIRequest.fetchTasks(status: status)
        let response: [ApiClient.TaskDto] = try await apiClient.performRequest(request)

        let fetchedTasks = response.map { dto in
            UserTask(
                id: dto.id,
                userId: dto.userId,
                title: dto.title,
                description: dto.description,
                status: UserTask.Status(rawValue: dto.status) ?? .todo,
                createdAt: dto.createdAt,
                updatedAt: dto.updatedAt
            )
        }

        // Update cache
        tasks = fetchedTasks
        updateActiveTasks()
        saveCachedTasks()

        return fetchedTasks
    }

    func fetchActiveTasks() async throws -> [UserTask] {
        let request = APIRequest.fetchActiveTasks
        let response: [ApiClient.TaskDto] = try await apiClient.performRequest(request)

        let activeTasks = response.map { dto in
            UserTask(
                id: dto.id,
                userId: dto.userId,
                title: dto.title,
                description: dto.description,
                status: UserTask.Status(rawValue: dto.status) ?? .todo,
                createdAt: dto.createdAt,
                updatedAt: dto.updatedAt
            )
        }

        self.activeTasks = activeTasks
        return activeTasks
    }

    func fetchTask(byId id: String) async throws -> UserTask {
        let request = APIRequest.fetchTask(id: id)
        let response: ApiClient.TaskDto = try await apiClient.performRequest(request)

        let task = UserTask(
            id: response.id,
            userId: response.userId,
            title: response.title,
            description: response.description,
            status: UserTask.Status(rawValue: response.status) ?? .todo,
            createdAt: response.createdAt,
            updatedAt: response.updatedAt
        )

        return task
    }

    // MARK: - Task Updates

    func updateTask(id: String, title: String? = nil, description: String? = nil, status: ApiTaskStatus? = nil) async throws -> UserTask {
        // Validate input if provided
        if let title = title {
            try validateTaskInput(title: title, description: nil)
        }
        if let description = description {
            try validateTaskInput(title: "", description: description)
        }

        let request = APIRequest.updateTask(id: id, title: title, description: description, status: status)
        let response: ApiClient.TaskDto = try await apiClient.performRequest(request)

        let updatedTask = UserTask(
            id: response.id,
            userId: response.userId,
            title: response.title,
            description: response.description,
            status: UserTask.Status(rawValue: response.status) ?? .todo,
            createdAt: response.createdAt,
            updatedAt: response.updatedAt
        )

        // Update local cache
        if let index = tasks.firstIndex(where: { $0.id.uuidString == id }) {
            tasks[index] = updatedTask
            updateActiveTasks()
            saveCachedTasks()
        }

        return updatedTask
    }

    func updateTask(_ task: UserTask, title: String? = nil, description: String? = nil, status: ApiTaskStatus? = nil) async throws -> UserTask {
        return try await updateTask(id: task.id.uuidString, title: title, description: description, status: status)
    }

    // MARK: - Task Deletion

    func deleteTask(id: String) async throws {
        let request = APIRequest.deleteTask(id: id)
        _ = try await apiClient.performRequest(request) as ApiClient.EmptyResponse

        // Update local cache
        tasks.removeAll { $0.id.uuidString == id }
        updateActiveTasks()
        saveCachedTasks()
    }

    func deleteTask(_ task: UserTask) async throws {
        try await deleteTask(id: task.id.uuidString)
    }

    // MARK: - Recycle Bin Management

    func softDeleteTask(_ task: UserTask) async throws {
        // Move task to recycle bin instead of hard delete
        let deletedTask = UserTask(
            id: task.id,
            userId: task.userId,
            title: task.title,
            description: task.description,
            status: .completed, // Mark as completed in recycle bin
            createdAt: task.createdAt,
            updatedAt: Date()
        )

        // Store in recycle bin with expiration
        let recycleBinItem = RecycleBinItem(task: deletedTask, deletedAt: Date())
        addToRecycleBin(recycleBinItem)

        // Remove from active tasks
        tasks.removeAll { $0.id == task.id }
        activeTasks.removeAll { $0.id == task.id }
        updateActiveTasks()
        saveCachedTasks()
    }

    func restoreTask(from recycleBinItem: RecycleBinItem) async throws {
        // Restore task from recycle bin
        let restoredTask = UserTask(
            id: recycleBinItem.task.id,
            userId: recycleBinItem.task.userId,
            title: recycleBinItem.task.title,
            description: recycleBinItem.task.description,
            status: .todo, // Reset to todo when restored
            createdAt: recycleBinItem.task.createdAt,
            updatedAt: Date()
        )

        // Add back to active tasks
        tasks.append(restoredTask)
        updateActiveTasks()
        saveCachedTasks()

        // Remove from recycle bin
        removeFromRecycleBin(recycleBinItem)
    }

    func getRecycleBinItems() -> [RecycleBinItem] {
        return loadRecycleBinItems().filter { !$0.isExpired }
    }

    func permanentlyDeleteExpiredItems() {
        let items = loadRecycleBinItems()
        let validItems = items.filter { !$0.isExpired }
        saveRecycleBinItems(validItems)
    }


    // MARK: - Task Completion Undo

    func undoTaskCompletion(_ task: UserTask) async throws -> UserTask {
        // Change status back to previous state (assuming inProgress for undo)
        return try await updateTask(task, status: .inProgress)
    }

    // MARK: - Local Cache Management

    private func loadCachedTasks() {
        guard let data = UserDefaults.standard.data(forKey: "TaskService.tasks.v1") else { return }

        do {
            let cachedTasks = try JSONDecoder().decode([UserTask].self, from: data)
            tasks = cachedTasks
            updateActiveTasks()
        } catch {
            // Clear corrupted cache
            UserDefaults.standard.removeObject(forKey: "TaskService.tasks.v1")
        }
    }

    private func saveCachedTasks() {
        do {
            let data = try JSONEncoder().encode(tasks)
            UserDefaults.standard.set(data, forKey: "TaskService.tasks.v1")
        } catch {
            // Ignore cache save failures
        }
    }

    private func updateActiveTasks() {
        activeTasks = tasks.filter { $0.status == .todo || $0.status == .inProgress }
    }

    // MARK: - Task Progress and Auto-completion

    func getTaskProgress(_ task: UserTask) async throws -> TaskProgress {
        // This would typically fetch session data from the backend
        // For now, return mock progress data
        return TaskProgress(
            taskId: task.id,
            completedSessions: 2, // Mock data
            totalEstimatedSessions: 4, // Mock data
            totalTimeSpent: 1500, // 25 minutes in seconds
            isAutoCompletable: false
        )
    }

    func markTaskCompletedIfEligible(_ task: UserTask) async throws -> Bool {
        let progress = try await getTaskProgress(task)

        // Auto-complete logic: if task has been worked on for more than 2 hours
        // or has more than 8 completed sessions
        let shouldAutoComplete = progress.totalTimeSpent > (2 * 60 * 60) || // 2 hours
                                progress.completedSessions >= 8

        if shouldAutoComplete && task.status != .completed {
            _ = try await updateTask(task, status: .completed)
            return true
        }

        return false
    }

    func suggestTaskCompletion(_ task: UserTask) async throws -> TaskCompletionSuggestion? {
        let progress = try await getTaskProgress(task)

        // Suggest completion if task has been inactive for a week
        // or has accumulated significant time
        let daysSinceLastUpdate = Calendar.current.dateComponents([.day], from: task.updatedAt, to: Date()).day ?? 0
        let isInactive = daysSinceLastUpdate > 7
        let hasSignificantTime = progress.totalTimeSpent > (30 * 60) // 30 minutes

        if isInactive && hasSignificantTime && task.status == .inProgress {
            return TaskCompletionSuggestion(
                taskId: task.id,
                reason: .inactiveTooLong,
                suggestedAction: .markCompleted,
                confidence: 0.8
            )
        }

        return nil
    }

    // MARK: - Task-Based Timer Integration

    func startTimerWithTask(_ task: UserTask) async throws {
        // This would integrate with the PomodoroTimer to start a session with this task
        // For now, this is a placeholder for the integration
        AppLogger.info("timer_started_with_task taskId: \(task.id.uuidString)", category: .timer)
    }

    func getRecommendedTasksForTimer() async throws -> [UserTask] {
        // Return tasks that are in progress and haven't been worked on recently
        let activeTasks = tasks.filter { $0.status == .inProgress }
        let sortedByLastUpdate = activeTasks.sorted { $0.updatedAt < $1.updatedAt }
        return Array(sortedByLastUpdate.prefix(3)) // Return top 3
    }

    // MARK: - Recycle Bin Storage Helpers

    private func addToRecycleBin(_ item: RecycleBinItem) {
        var items = loadRecycleBinItems()
        items.append(item)
        saveRecycleBinItems(items)
    }

    func removeFromRecycleBin(_ item: RecycleBinItem) {
        var items = loadRecycleBinItems()
        items.removeAll { $0.id == item.id }
        saveRecycleBinItems(items)
    }

    private func loadRecycleBinItems() -> [RecycleBinItem] {
        guard let data = UserDefaults.standard.data(forKey: "TaskService.recycleBin.v1") else { return [] }

        do {
            return try JSONDecoder().decode([RecycleBinItem].self, from: data)
        } catch {
            // Clear corrupted recycle bin data
            UserDefaults.standard.removeObject(forKey: "TaskService.recycleBin.v1")
            return []
        }
    }

    private func saveRecycleBinItems(_ items: [RecycleBinItem]) {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: "TaskService.recycleBin.v1")
        } catch {
            // Ignore save failures
        }
    }

    // MARK: - Validation

    private func validateTaskInput(title: String, description: String?) throws {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw TaskServiceError.validationError("Title cannot be empty")
        }
        if title.count > 255 {
            throw TaskServiceError.validationError("Title cannot exceed 255 characters")
        }
        if let description = description, description.count > 1000 {
            throw TaskServiceError.validationError("Description cannot exceed 1000 characters")
        }
    }
}

// MARK: - Supporting Types

enum ApiTaskStatus: String, Codable {
    case todo, inProgress = "in_progress", completed
}


struct TaskCreateRequest: Codable {
    let title: String
    let description: String?
}

struct TaskUpdateRequest: Codable {
    let title: String?
    let description: String?
    let status: String?
}

enum TaskServiceError: LocalizedError {
    case validationError(String)
    case networkError(Error)
    case notFound
    case unauthorized
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .validationError(let message):
            return message
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .notFound:
            return "Task not found"
        case .unauthorized:
            return "Authentication required. Please log in again."
        case .serverError(let message):
            return message
        }
    }
}

// MARK: - Task Progress Types

struct TaskProgress {
    let taskId: UUID
    let completedSessions: Int
    let totalEstimatedSessions: Int
    let totalTimeSpent: TimeInterval // in seconds
    let isAutoCompletable: Bool

    var progressPercentage: Double {
        guard totalEstimatedSessions > 0 else { return 0 }
        return Double(completedSessions) / Double(totalEstimatedSessions)
    }

    var formattedTimeSpent: String {
        let hours = Int(totalTimeSpent) / 3600
        let minutes = (Int(totalTimeSpent) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct TaskCompletionSuggestion {
    let taskId: UUID
    let reason: CompletionReason
    let suggestedAction: SuggestedAction
    let confidence: Double // 0.0 to 1.0

    enum CompletionReason {
        case inactiveTooLong
        case sufficientTimeSpent
        case sessionsCompleted
        case manualReview
    }

    enum SuggestedAction {
        case markCompleted
        case archive
        case review
    }
}

// MARK: - Recycle Bin Types

struct RecycleBinItem: Codable, Identifiable {
    let id: UUID
    let task: UserTask
    let deletedAt: Date
    let expiresAt: Date

    init(task: UserTask, deletedAt: Date) {
        self.id = UUID()
        self.task = task
        self.deletedAt = deletedAt
        // 30 days expiration
        self.expiresAt = deletedAt.addingTimeInterval(30 * 24 * 60 * 60)
    }

    var isExpired: Bool {
        return Date() > expiresAt
    }

    var daysUntilExpiration: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expiresAt)
        return max(0, components.day ?? 0)
    }
}

// MARK: - API Request Types

enum APIRequest {
    case createTask(title: String, description: String?)
    case fetchTasks(status: ApiTaskStatus?)
    case fetchActiveTasks
    case fetchTask(id: String)
    case updateTask(id: String, title: String?, description: String?, status: ApiTaskStatus?)
    case deleteTask(id: String)
}

// MARK: - Protocols

protocol ApiClientProtocol {
    func performRequest<T: Decodable>(_ request: APIRequest) async throws -> T
}

protocol KeychainStoreProtocol {
    func loadString(_ key: String) -> String?
    func saveString(_ value: String, forKey key: String) -> Bool
    func deleteString(_ key: String) -> Bool
}

// MARK: - Extensions

extension ApiClient: ApiClientProtocol {
    func performRequest<T: Decodable>(_ request: APIRequest) async throws -> T {
        switch request {
        case .createTask(let title, let description):
            let taskRequest = TaskCreateRequest(title: title, description: description)
            return try await createTask(taskRequest, accessToken: getAccessToken()) as! T

        case .fetchTasks(let status):
            let apiStatus = status.map { ApiTaskStatus(rawValue: $0.rawValue)! }
            return try await fetchTasks(accessToken: getAccessToken()) as! T

        case .fetchActiveTasks:
            return try await fetchActiveTasks(accessToken: getAccessToken()) as! T

        case .fetchTask(let id):
            guard let uuid = UUID(uuidString: id) else {
                throw TaskServiceError.validationError("Invalid task ID")
            }
            return try await fetchTask(id: uuid, accessToken: getAccessToken()) as! T

        case .updateTask(let id, let title, let description, let status):
            guard let uuid = UUID(uuidString: id) else {
                throw TaskServiceError.validationError("Invalid task ID")
            }
            let updateRequest = TaskUpdateRequest(title: title, description: description, status: status?.rawValue)
            return try await updateTask(id: uuid, updateRequest, accessToken: getAccessToken()) as! T

        case .deleteTask(let id):
            guard let uuid = UUID(uuidString: id) else {
                throw TaskServiceError.validationError("Invalid task ID")
            }
            try await deleteTask(id: uuid, accessToken: getAccessToken())
            return ApiClient.EmptyResponse() as! T
        }
    }

    private func getAccessToken() throws -> String {
        do {
            guard let token = try KeychainStore.loadString(.accessToken) else {
                throw TaskServiceError.unauthorized
            }
            return token
        } catch {
            throw TaskServiceError.unauthorized
        }
    }
}

extension KeychainStore: KeychainStoreProtocol {}