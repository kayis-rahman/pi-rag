import Foundation

class AnalyticsApiClient {
    private let baseURL: URL

    init(baseURL: URL) {
        self.baseURL = baseURL
    }

    func fetchDashboard(jwt: String, timeRange: String = "week", breakdown: String = "weekday") async throws -> AnalyticsDashboardResponse {
        guard var components = URLComponents(url: baseURL.appendingPathComponent("/api/v1/analytics/dashboard"), resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        components.queryItems = [
            URLQueryItem(name: "timeRange", value: timeRange),
            URLQueryItem(name: "breakdown", value: breakdown)
        ]
        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30 // Add timeout

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(http.statusCode) else {
            // Provide more specific error for different status codes
            switch http.statusCode {
            case 401:
                throw NSError(domain: "AnalyticsAPI", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authentication required. Please sign in."])
            case 403:
                throw NSError(domain: "AnalyticsAPI", code: 403, userInfo: [NSLocalizedDescriptionKey: "Access denied. Please check your permissions."])
            case 404:
                throw NSError(domain: "AnalyticsAPI", code: 404, userInfo: [NSLocalizedDescriptionKey: "Analytics endpoint not found. Backend may not be running."])
            case 500...599:
                throw NSError(domain: "AnalyticsAPI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error. Please try again later."])
            default:
                throw NSError(domain: "AnalyticsAPI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Request failed with status \(http.statusCode)"])
            }
        }

        let decoder = JSONDecoder()
        return try decoder.decode(AnalyticsDashboardResponse.self, from: data)
    }
}
