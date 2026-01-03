import SwiftUI

struct SidebarTabView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var taskService: TaskService
    @EnvironmentObject var timer: PomodoroTimer

    private let tabs: [(icon: String, label: String, badge: String?)] = [
        (icon: "house.fill", label: "Home", badge: nil),
        (icon: "checklist", label: "Tasks", badge: nil),
        (icon: "chart.bar.fill", label: "Status", badge: nil),
        (icon: "person.circle", label: "Profile", badge: nil)
    ]

    var body: some View {
        VStack(spacing: 16) {
            appLogoSection
            tabButtonsSection
            Spacer()
            quickActionsSection
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 8)
        .background(
            Color.themeCardBackground.opacity(0.95)
                .blur(radius: 0.5)
                .overlay(
                    Rectangle()
                        .fill(Color.themePrimary.opacity(0.05))
                        .frame(width: 1)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 2, y: 0)
        .padding(.vertical, 8)
        .padding(.leading, 8)
    }

    // MARK: - Computed Views

    private var appLogoSection: some View {
        VStack(spacing: 4) {
            Image(systemName: "timer.circle.fill")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.themePrimary)
                .padding(6)
                .background(
                    Circle()
                        .fill(Color.themeCardBackground.opacity(0.8))
                        .blur(radius: 1)
                )

            Text("TimeBeam")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.themePrimary.opacity(0.8))
                .opacity(0.8)
        }
        .padding(.bottom, 24)
    }

    private var tabButtonsSection: some View {
        VStack(spacing: 4) {
            ForEach(0..<tabs.count, id: \.self) { index in
                SidebarTabButton(
                    icon: tabs[index].icon,
                    label: tabs[index].label,
                    isSelected: selectedTab == index,
                    badge: badgeForTab(index),
                    hasActiveIndicator: hasActiveIndicator(for: index)
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                }
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(spacing: 8) {
            if timer.isRunning {
                Circle()
                    .fill(Color.themePrimary)
                    .frame(width: 8, height: 8)
                    .opacity(timer.isRunning ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(), value: timer.isRunning)
            }

            Button {
                // Quick settings or help
                withAnimation {
                    // Could show a quick menu or navigate to settings
                }
            } label: {
                Image(systemName: "gear")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.bottom, 20)
    }

    private var sidebarCardStyle: some View {
        self
            .padding(.vertical, 20)
            .padding(.horizontal, 8)
            .background(
                Color.themeCardBackground.opacity(0.95)
                    .blur(radius: 0.5)
                    .overlay(
                        Rectangle()
                            .fill(Color.themePrimary.opacity(0.05))
                            .frame(width: 1)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 2, y: 0)
            .padding(.vertical, 8)
            .padding(.leading, 8)
    }

    private func badgeForTab(_ index: Int) -> String? {
        switch index {
        case 1: // Tasks
            let activeCount = taskService.activeTasks.count
            return activeCount > 0 ? "\(activeCount)" : nil
        case 2: // Status
            return timer.isRunning ? "●" : nil
        default:
            return nil
        }
    }

    private func hasActiveIndicator(for index: Int) -> Bool {
        switch index {
        case 0: // Home
            return timer.currentTaskId != nil
        case 1: // Tasks
            return taskService.activeTasks.contains { $0.status == .inProgress }
        default:
            return false
        }
    }
}
