import Foundation

struct UserTaskBreakdownSection: Decodable {
    let data: [UserTaskBreakdownEntry]
    let period: Int
    let timezone: String
}
