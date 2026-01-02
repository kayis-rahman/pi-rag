import Foundation

struct LoginResponse: Codable {
    let accessToken: String
    let user: User?
}
