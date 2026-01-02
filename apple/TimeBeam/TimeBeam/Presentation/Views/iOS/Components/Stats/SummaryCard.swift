// Extracted from StatsView.swift

import SwiftUI


    private func formatDuration(_ minutes: Int) -> String {
        return "\(minutes)m"
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Data Models

struct DailyStats: Identifiable {
    let id = UUID()
    let date: Date
    let dayLabel: String
    let minutes: Int
}

#Preview {
    StatsView()
        .environmentObject(SessionLogger())
        .environmentObject(AnalyticsManager(
            apiClient: AnalyticsApiClient(baseURL: URL(string: "https://api.example.com")!),
            authManager: AuthManager()
        ))
}
