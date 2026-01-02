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
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                BottomTabButton(
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
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            Color.themeCardBackground.opacity(0.95)
                .blur(radius: 0.5)
                .overlay(
                    Rectangle()
                        .fill(Color.themePrimary.opacity(0.05))
                        .frame(height: 1)
                        .frame(maxWidth: .infinity, alignment: .top)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -2)
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
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

struct BottomTabButton: View {