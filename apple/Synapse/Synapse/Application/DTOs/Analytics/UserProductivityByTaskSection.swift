import Foundation

struct UserProductivityByTaskSection: Decodable {
    let data: [UserProductivityByTaskEntry]
    let period: Int
    let timezone: String
}
