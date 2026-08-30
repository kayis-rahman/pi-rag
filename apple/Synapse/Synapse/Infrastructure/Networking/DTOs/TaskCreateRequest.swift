import Foundation

struct TaskCreateRequest: Codable {
    let title: String
    let description: String?
}
