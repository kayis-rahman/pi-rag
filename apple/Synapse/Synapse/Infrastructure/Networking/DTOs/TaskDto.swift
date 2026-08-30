import Foundation

struct TaskDto: Codable {
    let id: UUID
    let userId: UUID
    let title: String
    let description: String?
    let status: String
    let createdAt: Date
    let updatedAt: Date
}
