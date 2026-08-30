import Foundation

struct DeviceRegistrationDto: Codable {
    let deviceId: String
    let deviceName: String
    let deviceType: String
    let platformVersion: String
    let appVersion: String
    let fcmToken: String?
}
