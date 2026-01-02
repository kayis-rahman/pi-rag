import Foundation

/// API configuration for base URL and endpoints
struct APIConfiguration {
    let baseURL: URL

    static func fromInfoPlist() -> APIConfiguration? {
        guard
            let dict = Bundle.main.infoDictionary,
            let base = dict["API_BASE_URL"] as? String,
            let url = URL(string: base)
        else { return nil }
        return APIConfiguration(baseURL: url)
    }
}
