import Foundation

struct TaskUpdateRequest: Codable {
    let title: String?
    let description: String?
    let status: String?
}
