import Foundation

@MainActor
class AnalyticsManager: ObservableObject {

    @Published var dashboardData: AnalyticsDashboardResponse?

    @Published var isLoading = false

    @Published var error: Error?



    private let apiClient: AnalyticsApiClient

    private let authManager: AuthManager



    init(apiClient: AnalyticsApiClient, authManager: AuthManager) {

        self.apiClient = apiClient

        self.authManager = authManager

    }



    func fetchDashboard(timeRange: String = "week", breakdown: String = "weekday") async {

        guard authManager.isSignedIn,

              Configuration.fromInfoPlist() != nil else {

            // Not signed in or no API config, use local data

            return

        }



        isLoading = true

        error = nil



        do {

            let jwt = try KeychainStore.loadString(.accessToken) ?? ""

            let response = try await apiClient.fetchDashboard(jwt: jwt, timeRange: timeRange, breakdown: breakdown)

            dashboardData = response

        } catch {

            self.error = error

            print("Failed to fetch analytics dashboard: \(error)")

        }



        isLoading = false

    }



    // MARK: - Computed Properties for UI



    var weeklyChartData: [DailyStats] {

        if let apiData = dashboardData?.dailyTotals.data {

            // Convert API data to chart format

            return apiData.map { entry in

                let date = ISO8601DateFormatter().date(from: entry.date) ?? Date()

                let isToday = Calendar.current.isDateInToday(date)

                return DailyStats(

                    date: date,

                    dayLabel: isToday ? "Today" : formatDay(date),

                    minutes: entry.totalMinutes

                )

            }

        } else {

            // Fall back to local data

            return []

        }

    }



    var todayTotal: Int {

        dashboardData?.dailyTotals.data.last?.totalMinutes ?? 0

    }



    var weeklyTotal: Int {

        dashboardData?.dailyTotals.data.reduce(0) { $0 + $1.totalMinutes } ?? 0

    }



    var bestStreak: Int {

        dashboardData?.streak.current ?? 0

    }



    var recentSessions: [SessionRecord] {

        // This would need to be fetched separately or from local data

        // For now, return empty array as this data isn't in the dashboard response

        []

    }



    private func formatDay(_ date: Date) -> String {

        let formatter = DateFormatter()

        formatter.dateFormat = "EEE"

        return formatter.string(from: date)

    }

}
