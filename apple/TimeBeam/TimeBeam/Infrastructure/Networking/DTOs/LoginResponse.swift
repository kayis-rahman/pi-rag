import Foundation

struct LoginResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let user: User?
}
