//
//  PerformanceDashboard.swift
//  TimeBeam Testing Framework
//
//  Performance monitoring and dashboard generation
//

import Foundation

/// Performance monitoring and dashboard for test results
public class PerformanceDashboard {
    
    // MARK: - Properties
    
    private var performanceMetrics: [TestPerformanceMetrics] = []
    private var aggregatedMetrics: AggregatedPerformanceMetrics?
    
    // MARK: - Metrics Collection
    
    /// Add performance metrics
    public func addMetrics(_ metrics: TestPerformanceMetrics) {
        performanceMetrics.append(metrics)
        updateAggregatedMetrics()
    }
    
    /// Get all performance metrics
    public func getAllMetrics() -> [TestPerformanceMetrics] {
        return performanceMetrics
    }
    
    /// Get aggregated performance metrics
    public func getAggregatedMetrics() -> AggregatedPerformanceMetrics? {
        return aggregatedMetrics
    }
    
    // MARK: - Report Generation
    
    /// Generate performance summary
    public func generateSummary(testResults: [TestResult]) async {
        print("📊 Performance Dashboard Summary")
        print("=" * 40)
        
        // Filter tests with performance metrics
        let testsWithMetrics = testResults.compactMap { result in
            result.metrics.map { (result.testName, $0) }
        }
        
        guard !testsWithMetrics.isEmpty else {
            print("⚠️ No performance metrics available")
            return
        }
        
        // CPU Performance
        await generateCPUSummary(testsWithMetrics: testsWithMetrics)
        
        // Memory Performance
        await generateMemorySummary(testsWithMetrics: testsWithMetrics)
        
        // Network Performance
        await generateNetworkSummary(testsWithMetrics: testsWithMetrics)
        
        // Battery Performance
        await generateBatterySummary(testsWithMetrics: testsWithMetrics)
        
        // Database Performance
        await generateDatabaseSummary(testsWithMetrics: testsWithMetrics)
        
        // Overall Performance Score
        await generatePerformanceScore(testsWithMetrics: testsWithMetrics)
    }
    
    /// Generate detailed performance report
    public func generateDetailedReport() -> String {
        var report = "# TimeBeam Performance Report\n\n"
        report += "Generated at: \(Date())\n\n"
        
        report += "## Executive Summary\n\n"
        
        if let aggregated = aggregatedMetrics {
            report += "- **Overall Performance Score**: \(String(format: "%.1f", aggregated.overallScore))/100\n"
            report += "- **Average CPU Usage**: \(String(format: "%.1f", aggregated.averageCPUUsage))%\n"
            report += "- **Average Memory Usage**: \(String(format: "%.1f", aggregated.averageMemoryUsageMB))MB\n"
            report += "- **Average Network Latency**: \(String(format: "%.0f", aggregated.averageLatencyMs))ms\n"
            report += "- **Battery Efficiency**: \(String(format: "%.1f", aggregated.batteryEfficiencyScore))/100\n"
            report += "- **Database Performance**: \(String(format: "%.1f", aggregated.databasePerformanceScore))/100\n\n"
        }
        
        // Detailed breakdown
        report += generateCPUDetails()
        report += generateMemoryDetails()
        report += generateNetworkDetails()
        report += generateBatteryDetails()
        report += generateDatabaseDetails()
        
        // Recommendations
        report += generateRecommendations()
        
        return report
    }
    
    /// Export performance metrics to JSON
    public func exportToJSON() -> Data? {
        guard let aggregated = aggregatedMetrics else { return nil }
        
        let exportData: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "overallScore": aggregated.overallScore,
            "cpuMetrics": [
                "averageUsage": aggregated.averageCPUUsage,
                "peakUsage": aggregated.peakCPUUsage,
                "score": aggregated.cpuScore
            ],
            "memoryMetrics": [
                "averageUsageMB": aggregated.averageMemoryUsageMB,
                "peakUsageMB": aggregated.peakMemoryUsageMB,
                "memoryLeakDetected": aggregated.memoryLeakDetected,
                "score": aggregated.memoryScore
            ],
            "networkMetrics": [
                "averageLatencyMs": aggregated.averageLatencyMs,
                "peakLatencyMs": aggregated.peakLatencyMs,
                "successRate": aggregated.networkSuccessRate,
                "score": aggregated.networkScore
            ],
            "batteryMetrics": [
                "efficiencyScore": aggregated.batteryEfficiencyScore,
                "drainRate": aggregated.batteryDrainRate,
                "score": aggregated.batteryScore
            ],
            "databaseMetrics": [
                "performanceScore": aggregated.databasePerformanceScore,
                "averageQueryTime": aggregated.averageDatabaseQueryTime,
                "successRate": aggregated.databaseSuccessRate,
                "score": aggregated.databaseScore
            ],
            "testMetrics": performanceMetrics.map { metrics in
                [
                    "testID": metrics.testID,
                    "deviceID": metrics.deviceID,
                    "duration": metrics.duration,
                    "cpuUsage": metrics.cpuMetrics.averageUsage,
                    "memoryUsage": metrics.memoryMetrics.averageUsage / (1024 * 1024),
                    "networkLatency": metrics.networkMetrics.averageLatency * 1000,
                    "batteryDrain": metrics.batteryMetrics.drainRate
                ]
            }
        ]
        
        return try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
    }
    
    // MARK: - Private Methods
    
    private func updateAggregatedMetrics() {
        guard !performanceMetrics.isEmpty else { return }
        
        let cpuUsages = performanceMetrics.map { $0.cpuMetrics.averageUsage }
        let memoryUsages = performanceMetrics.map { $0.memoryMetrics.averageUsage / (1024 * 1024) } // Convert to MB
        let networkLatencies = performanceMetrics.map { $0.networkMetrics.averageLatency * 1000 } // Convert to ms
        let batteryDrains = performanceMetrics.map { $0.batteryMetrics.drainRate }
        
        aggregatedMetrics = AggregatedPerformanceMetrics(
            overallScore: calculateOverallScore(),
            averageCPUUsage: cpuUsages.reduce(0, +) / Double(cpuUsages.count),
            peakCPUUsage: performanceMetrics.map { $0.cpuMetrics.peakUsage }.max() ?? 0,
            averageMemoryUsageMB: memoryUsages.reduce(0, +) / Double(memoryUsages.count),
            peakMemoryUsageMB: performanceMetrics.map { $0.memoryMetrics.peakUsage / (1024 * 1024) }.max() ?? 0,
            memoryLeakDetected: performanceMetrics.contains { $0.memoryMetrics.leaksDetected > 0 },
            averageLatencyMs: networkLatencies.reduce(0, +) / Double(networkLatencies.count),
            peakLatencyMs: performanceMetrics.map { $0.networkMetrics.peakLatency * 1000 }.max() ?? 0,
            networkSuccessRate: performanceMetrics.map { $0.networkMetrics.successRate }.reduce(0, +) / Double(performanceMetrics.count),
            batteryDrainRate: batteryDrains.reduce(0, +) / Double(batteryDrains.count),
            batteryEfficiencyScore: calculateBatteryEfficiencyScore(),
            averageDatabaseQueryTime: performanceMetrics.map { $0.databaseMetrics.averageQueryTime }.reduce(0, +) / Double(performanceMetrics.count),
            databaseSuccessRate: performanceMetrics.map { $0.databaseMetrics.querySuccessRate }.reduce(0, +) / Double(performanceMetrics.count),
            cpuScore: calculateCPUScore(),
            memoryScore: calculateMemoryScore(),
            networkScore: calculateNetworkScore(),
            batteryScore: calculateBatteryScore(),
            databaseScore: calculateDatabaseScore()
        )
    }
    
    private func calculateOverallScore() -> Double {
        let cpuScore = calculateCPUScore()
        let memoryScore = calculateMemoryScore()
        let networkScore = calculateNetworkScore()
        let batteryScore = calculateBatteryScore()
        let databaseScore = calculateDatabaseScore()
        
        return (cpuScore + memoryScore + networkScore + batteryScore + databaseScore) / 5.0
    }
    
    private func calculateCPUScore() -> Double {
        let averageUsage = performanceMetrics.map { $0.cpuMetrics.averageUsage }.reduce(0, +) / Double(performanceMetrics.count)
        return max(0, 100 - averageUsage) // Lower CPU usage = higher score
    }
    
    private func calculateMemoryScore() -> Double {
        let memoryIncrease = performanceMetrics.map { $0.memoryMetrics.memoryIncrease }.reduce(0, +) / Double(performanceMetrics.count)
        let leaksDetected = performanceMetrics.contains { $0.memoryMetrics.leaksDetected > 0 }
        
        if leaksDetected {
            return 0 // Any memory leaks result in 0 score
        }
        
        let memoryIncreaseMB = memoryIncrease / (1024 * 1024)
        return max(0, 100 - memoryIncreaseMB) // Lower memory increase = higher score
    }
    
    private func calculateNetworkScore() -> Double {
        let averageLatency = performanceMetrics.map { $0.networkMetrics.averageLatency * 1000 }.reduce(0, +) / Double(performanceMetrics.count)
        let successRate = performanceMetrics.map { $0.networkMetrics.successRate }.reduce(0, +) / Double(performanceMetrics.count)
        
        let latencyScore = max(0, 100 - averageLatency / 10) // 100ms = 0 points
        let successScore = successRate * 100 // Convert to 0-100 scale
        
        return (latencyScore + successScore) / 2.0
    }
    
    private func calculateBatteryScore() -> Double {
        let drainRate = performanceMetrics.map { $0.batteryMetrics.drainRate }.reduce(0, +) / Double(performanceMetrics.count)
        return max(0, 100 - drainRate * 10) // 10% drain per hour = 0 points
    }
    
    private func calculateBatteryEfficiencyScore() -> Double {
        return calculateBatteryScore()
    }
    
    private func calculateDatabaseScore() -> Double {
        let averageQueryTime = performanceMetrics.map { $0.databaseMetrics.averageQueryTime }.reduce(0, +) / Double(performanceMetrics.count)
        let successRate = performanceMetrics.map { $0.databaseMetrics.querySuccessRate }.reduce(0, +) / Double(performanceMetrics.count)
        
        let queryScore = max(0, 100 - averageQueryTime * 1000) // 100ms = 0 points
        let successScore = successRate * 100 // Convert to 0-100 scale
        
        return (queryScore + successScore) / 2.0
    }
    
    private func generateCPUSummary(testsWithMetrics: [(String, TestPerformanceMetrics)]) async {
        print("💻 CPU Performance:")
        
        let cpuUsages = testsWithMetrics.map { $0.1.cpuMetrics.averageUsage }
        let averageCPU = cpuUsages.reduce(0, +) / Double(cpuUsages.count)
        let peakCPU = testsWithMetrics.map { $0.1.cpuMetrics.peakUsage }.max() ?? 0
        
        print("  Average Usage: \(String(format: "%.1f", averageCPU))%")
        print("  Peak Usage: \(String(format: "%.1f", peakCPU))%")
        
        if averageCPU > 70 {
            print("  ⚠️ High CPU usage detected")
        } else if averageCPU > 50 {
            print("  ⚡ Moderate CPU usage")
        } else {
            print("  ✅ Good CPU performance")
        }
        print("")
    }
    
    private func generateMemorySummary(testsWithMetrics: [(String, TestPerformanceMetrics)]) async {
        print("🧠 Memory Performance:")
        
        let memoryUsages = testsWithMetrics.map { $0.1.memoryMetrics.memoryIncrease / (1024 * 1024) } // Convert to MB
        let averageMemory = memoryUsages.reduce(0, +) / Double(memoryUsages.count)
        let peakMemory = testsWithMetrics.map { $0.1.memoryMetrics.peakUsage / (1024 * 1024) }.max() ?? 0
        let leaksDetected = testsWithMetrics.contains { $0.1.memoryMetrics.leaksDetected > 0 }
        
        print("  Average Increase: \(String(format: "%.1f", averageMemory))MB")
        print("  Peak Usage: \(String(format: "%.1f", peakMemory))MB")
        
        if leaksDetected {
            print("  ❌ Memory leaks detected!")
        } else if averageMemory > 100 {
            print("  ⚠️ High memory usage")
        } else if averageMemory > 50 {
            print("  ⚡ Moderate memory usage")
        } else {
            print("  ✅ Good memory performance")
        }
        print("")
    }
    
    private func generateNetworkSummary(testsWithMetrics: [(String, TestPerformanceMetrics)]) async {
        print("🌐 Network Performance:")
        
        let latencies = testsWithMetrics.map { $0.1.networkMetrics.averageLatency * 1000 } // Convert to ms
        let averageLatency = latencies.reduce(0, +) / Double(latencies.count)
        let peakLatency = testsWithMetrics.map { $0.1.networkMetrics.peakLatency * 1000 }.max() ?? 0
        let successRates = testsWithMetrics.map { $0.1.networkMetrics.successRate }
        let averageSuccessRate = successRates.reduce(0, +) / Double(successRates.count)
        
        print("  Average Latency: \(String(format: "%.0f", averageLatency))ms")
        print("  Peak Latency: \(String(format: "%.0f", peakLatency))ms")
        print("  Success Rate: \(String(format: "%.1f", averageSuccessRate * 100))%")
        
        if averageLatency > 500 {
            print("  ⚠️ High network latency")
        } else if averageLatency > 200 {
            print("  ⚡ Moderate network latency")
        } else {
            print("  ✅ Good network performance")
        }
        print("")
    }
    
    private func generateBatterySummary(testsWithMetrics: [(String, TestPerformanceMetrics)]) async {
        print("🔋 Battery Performance:")
        
        let drainRates = testsWithMetrics.map { $0.1.batteryMetrics.drainRate }
        let averageDrainRate = drainRates.reduce(0, +) / Double(drainRates.count)
        let totalDrains = testsWithMetrics.map { $0.1.batteryMetrics.batteryDrain }
        let averageTotalDrain = totalDrains.reduce(0, +) / Double(totalDrains.count)
        
        print("  Average Drain Rate: \(String(format: "%.1f", averageDrainRate))%/hour")
        print("  Average Total Drain: \(String(format: "%.1f", averageTotalDrain))%")
        
        if averageDrainRate > 10 {
            print("  ⚠️ High battery drain")
        } else if averageDrainRate > 5 {
            print("  ⚡ Moderate battery drain")
        } else {
            print("  ✅ Good battery efficiency")
        }
        print("")
    }
    
    private func generateDatabaseSummary(testsWithMetrics: [(String, TestPerformanceMetrics)]) async {
        print("💾 Database Performance:")
        
        let queryTimes = testsWithMetrics.map { $0.1.databaseMetrics.averageQueryTime * 1000 } // Convert to ms
        let averageQueryTime = queryTimes.reduce(0, +) / Double(queryTimes.count)
        let successRates = testsWithMetrics.map { $0.1.databaseMetrics.querySuccessRate }
        let averageSuccessRate = successRates.reduce(0, +) / Double(successRates.count)
        
        print("  Average Query Time: \(String(format: "%.0f", averageQueryTime))ms")
        print("  Success Rate: \(String(format: "%.1f", averageSuccessRate * 100))%")
        
        if averageQueryTime > 100 {
            print("  ⚠️ Slow database queries")
        } else if averageQueryTime > 50 {
            print("  ⚡ Moderate database performance")
        } else {
            print("  ✅ Good database performance")
        }
        print("")
    }
    
    private func generatePerformanceScore(testsWithMetrics: [(String, TestPerformanceMetrics)]) async {
        print("🏆 Overall Performance Score:")
        
        let score = calculateOverallScore()
        print("  Score: \(String(format: "%.1f", score))/100")
        
        if score >= 90 {
            print("  🌟 Excellent performance!")
        } else if score >= 80 {
            print("  ✅ Good performance")
        } else if score >= 70 {
            print("  ⚡ Acceptable performance")
        } else {
            print("  ⚠️ Performance needs improvement")
        }
        print("")
    }
    
    private func generateCPUDetails() -> String {
        var details = "## CPU Performance Details\n\n"
        
        for metrics in performanceMetrics {
            details += "### \(metrics.testID)\n"
            details += "- Average Usage: \(String(format: "%.1f", metrics.cpuMetrics.averageUsage))%\n"
            details += "- Peak Usage: \(String(format: "%.1f", metrics.cpuMetrics.peakUsage))%\n"
            details += "- Duration: \(String(format: "%.2f", metrics.duration))s\n\n"
        }
        
        return details
    }
    
    private func generateMemoryDetails() -> String {
        var details = "## Memory Performance Details\n\n"
        
        for metrics in performanceMetrics {
            let memoryIncreaseMB = metrics.memoryMetrics.memoryIncrease / (1024 * 1024)
            let peakUsageMB = metrics.memoryMetrics.peakUsage / (1024 * 1024)
            
            details += "### \(metrics.testID)\n"
            details += "- Memory Increase: \(String(format: "%.1f", memoryIncreaseMB))MB\n"
            details += "- Peak Usage: \(String(format: "%.1f", peakUsageMB))MB\n"
            details += "- Memory Leaks: \(metrics.memoryMetrics.leaksDetected)\n"
            details += "- Duration: \(String(format: "%.2f", metrics.duration))s\n\n"
        }
        
        return details
    }
    
    private func generateNetworkDetails() -> String {
        var details = "## Network Performance Details\n\n"
        
        for metrics in performanceMetrics {
            details += "### \(metrics.testID)\n"
            details += "- Average Latency: \(String(format: "%.0f", metrics.networkMetrics.averageLatency * 1000))ms\n"
            details += "- Peak Latency: \(String(format: "%.0f", metrics.networkMetrics.peakLatency * 1000))ms\n"
            details += "- Success Rate: \(String(format: "%.1f", metrics.networkMetrics.successRate * 100))%\n"
            details += "- Total Requests: \(metrics.networkMetrics.totalRequests)\n"
            details += "- Failed Requests: \(metrics.networkMetrics.failedRequests)\n\n"
        }
        
        return details
    }
    
    private func generateBatteryDetails() -> String {
        var details = "## Battery Performance Details\n\n"
        
        for metrics in performanceMetrics {
            details += "### \(metrics.testID)\n"
            details += "- Initial Level: \(String(format: "%.1f", metrics.batteryMetrics.initialLevel))%\n"
            details += "- Final Level: \(String(format: "%.1f", metrics.batteryMetrics.finalLevel))%\n"
            details += "- Battery Drain: \(String(format: "%.1f", metrics.batteryMetrics.batteryDrain))%\n"
            details += "- Drain Rate: \(String(format: "%.1f", metrics.batteryMetrics.drainRate))%/hour\n"
            details += "- Duration: \(String(format: "%.2f", metrics.duration))s\n\n"
        }
        
        return details
    }
    
    private func generateDatabaseDetails() -> String {
        var details = "## Database Performance Details\n\n"
        
        for metrics in performanceMetrics {
            details += "### \(metrics.testID)\n"
            details += "- Average Query Time: \(String(format: "%.0f", metrics.databaseMetrics.averageQueryTime * 1000))ms\n"
            details += "- Total Queries: \(metrics.databaseMetrics.totalQueries)\n"
            details += "- Slow Queries: \(metrics.databaseMetrics.slowQueries)\n"
            details += "- Success Rate: \(String(format: "%.1f", metrics.databaseMetrics.querySuccessRate * 100))%\n"
            details += "- Committed Transactions: \(metrics.databaseMetrics.transactionsCommitted)\n"
            details += "- Rolled Back Transactions: \(metrics.databaseMetrics.transactionsRolledBack)\n\n"
        }
        
        return details
    }
    
    private func generateRecommendations() -> String {
        var recommendations = "## Performance Recommendations\n\n"
        
        guard let aggregated = aggregatedMetrics else {
            return recommendations + "No performance data available for recommendations.\n"
        }
        
        if aggregated.cpuScore < 70 {
            recommendations += "- **CPU Optimization**: Consider optimizing timer update frequency and implementing more efficient sync algorithms.\n"
        }
        
        if aggregated.memoryScore < 70 {
            recommendations += "- **Memory Optimization**: Review memory management in timer state handling and implement better cache cleanup.\n"
        }
        
        if aggregated.networkScore < 70 {
            recommendations += "- **Network Optimization**: Implement better retry logic and consider compression for timer state data.\n"
        }
        
        if aggregated.batteryScore < 70 {
            recommendations += "- **Battery Optimization**: Reduce background sync frequency and implement smarter heartbeat intervals.\n"
        }
        
        if aggregated.databaseScore < 70 {
            recommendations += "- **Database Optimization**: Add proper indexing and consider connection pooling for better performance.\n"
        }
        
        if aggregated.memoryLeakDetected {
            recommendations += "- **URGENT**: Memory leaks detected! Review timer state cleanup and device management code.\n"
        }
        
        if recommendations == "## Performance Recommendations\n\n" {
            recommendations += "Great job! All performance metrics are within acceptable ranges.\n"
        }
        
        return recommendations + "\n"
    }
}

// MARK: - Supporting Types

/// Aggregated performance metrics across all tests
public struct AggregatedPerformanceMetrics {
    let overallScore: Double
    let averageCPUUsage: Double
    let peakCPUUsage: Double
    let averageMemoryUsageMB: Double
    let peakMemoryUsageMB: Double
    let memoryLeakDetected: Bool
    let averageLatencyMs: Double
    let peakLatencyMs: Double
    let networkSuccessRate: Double
    let batteryDrainRate: Double
    let batteryEfficiencyScore: Double
    let averageDatabaseQueryTime: TimeInterval
    let databaseSuccessRate: Double
    let cpuScore: Double
    let memoryScore: Double
    let networkScore: Double
    let batteryScore: Double
    let databaseScore: Double
}