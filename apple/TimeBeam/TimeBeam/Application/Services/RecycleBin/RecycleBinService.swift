import Foundation

/// Service for managing the recycle bin functionality
/// Handles task deletion, restoration, and expiration
@MainActor
final class RecycleBinService: ObservableObject {
    private let recycleBinKey = "TaskService.recycleBin.v1"
    
    @Published private(set) var recycleBinItems: [RecycleBinItem] = []
    
    init() {
        loadRecycleBinItems()
    }
    
    // MARK: - Recycle Bin Management
    
    /// Restores a task from the recycle bin
    func restoreTask(from recycleBinItem: RecycleBinItem) async throws -> UserTask {
        // This would normally call TaskService.updateTask
        // For now, just return the task
        let restoredTask = UserTask(
            id: recycleBinItem.task.id,
            userId: recycleBinItem.task.userId,
            title: recycleBinItem.task.title,
            description: recycleBinItem.task.description,
            status: .todo, // Reset to todo when restored
            createdAt: recycleBinItem.task.createdAt,
            updatedAt: Date()
        )
        return restoredTask
    }
    
    func getRecycleBinItems() -> [RecycleBinItem] {
        return recycleBinItems.filter { !$0.isExpired }
    }
    
    func permanentlyDeleteExpiredItems() {
        let validItems = recycleBinItems.filter { !$0.isExpired }
        saveRecycleBinItems(validItems)
    }
    
    // MARK: - Private Storage Methods
    
    func addToRecycleBin(_ item: RecycleBinItem) {
        var items = loadRecycleBinItems()
        items.append(item)
        saveRecycleBinItems(items)
        recycleBinItems = items
    }
    
    func removeFromRecycleBin(_ item: RecycleBinItem) {
        var items = loadRecycleBinItems()
        items.removeAll { $0.id == item.id }
        saveRecycleBinItems(items)
        recycleBinItems = items
    }
    
    private func loadRecycleBinItems() -> [RecycleBinItem] {
        guard let data = UserDefaults.standard.data(forKey: recycleBinKey) else { return [] }
        do {
            return try JSONDecoder().decode([RecycleBinItem].self, from: data)
        } catch {
            return []
        }
    }
    
    private func saveRecycleBinItems(_ items: [RecycleBinItem]) {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: recycleBinKey)
        } catch {
            print("Failed to save recycle bin: \(error)")
        }
    }
}
