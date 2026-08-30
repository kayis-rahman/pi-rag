import Foundation

struct DeviceStats: Codable {
    let totalDevices: Int
    let activeDevices: Int
    let iosDevices: Int
    let macDevices: Int
    let watchosDevices: Int
    let lastSyncTime: Date
}
