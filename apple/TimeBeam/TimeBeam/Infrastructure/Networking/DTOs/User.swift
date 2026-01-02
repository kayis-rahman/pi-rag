import Foundation

struct User: Codable {
    let id: UUID
    let email: String
    let displayName: String
}
