import SwiftUI
import UserNotifications

#if os(macOS)
import AppKit
#endif

#if os(iOS)
import UIKit
#endif

#if os(macOS)
#elseif os(iOS)
#endif

enum TransitionDirection {
    case none, left, right, up, down
}

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        #if os(macOS)
        if #available(macOS 11.0, *) {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([.sound])
        }
        #else
        completionHandler([.banner, .sound, .badge])
        #endif
    }
}

struct TimeBeamApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(MacAppDelegate.self) var appDelegate
    #else
    @UIApplicationDelegateAdaptor(iOSAppDelegate.self) var appDelegate
    #endif

    @StateObject var timer = PomodoroTimer()
    // @StateObject var logger = SessionLogger()
    @StateObject var authManager = AuthManager.shared
    @StateObject var taskService = TaskService()
    @StateObject var analyticsManager = AnalyticsManager(
        apiClient: AnalyticsApiClient(baseURL: Configuration.fromInfoPlist()?.baseURL ?? URL(string: ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "http://192.168.0.173:8080")!),
        authManager: AuthManager.shared
    )

    @State private var isAppReady = false
    @State private var selectedTab = 0
    @State private var navigationPath = NavigationPath()
    @State private var isSidebarCollapsed = false
    @State private var previousTab = 0
    @State private var transitionDirection: TransitionDirection = .none

    var body: some Scene {
        WindowGroup {
            #if os(iOS)
            Group {
                if isAppReady {
                    NavigationView {
                        VStack(spacing: 0) {
                            // Main content area
                            ZStack {
                                mainContentView
                                    .transition(.opacity)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                            // Bottom tab bar
                            BottomTabView(selectedTab: $selectedTab)
                                .frame(height: 80)
                                .background(Color(.secondarySystemBackground))
                        }
                    }
                    .environmentObject(timer)
                // .environmentObject(logger)
                    .environmentObject(authManager)
                    .environmentObject(taskService)
                    .environmentObject(analyticsManager)
                    .accentColor(Color.themePrimary)
                    .navigationViewStyle(.stack)
                } else {
                    LoadingView()
                        .onAppear {
                            _Concurrency.Task {
                                await setupApp()
                            }
                        }
                }
            }
            #else
            macOSContentView()
                .environmentObject(timer)
                // .environmentObject(logger)
                .environmentObject(authManager)
                .environmentObject(taskService)
                .environmentObject(analyticsManager)
                .onAppear {
                    // Initialize file logging system
                    AppLogger.initializeFileLogging()
                    
                    _Concurrency.Task {
                        await authManager.restoreSession()

                        // macOS gets priority - wait longer to allow iOS to sync first if it's running
                        try? await _Concurrency.Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay


                    }
                }
                .onAppear {
                    timer.onSessionCompleted = { phase, duration in
                        let kind: SessionRecord.Kind
                        switch phase {
                            case .work: kind = .work
                            case .break: kind = .shortBreak
                            case .longBreak: kind = .longBreak
                        }
                        let start = Date().addingTimeInterval(-TimeInterval(duration))
                        _ = SessionRecord(startedAt: start, duration: TimeInterval(duration), kind: kind)
                        // logger.add(record: record)
                    }

                    // Configure timer sync manager
                    TimerSyncManager.shared.configure(with: timer)
                }
            #endif
        }
        #if os(macOS)
        .windowStyle(.automatic)
        #endif
    }

    private func setupApp() async {
        // Initialize file logging system
        AppLogger.initializeFileLogging()

        // Initialize iCloud sync
        _ = iCloudSyncManager.shared

        // Load timer settings from iCloud
        if let iCloudSettings = iCloudSyncManager.shared.loadTimerSettings() {
            timer.updateDurations(
                workMinutes: iCloudSettings.workDuration / 60,
                shortBreakMinutes: iCloudSettings.breakDuration / 60,
                longBreakMinutes: iCloudSettings.longBreakDuration / 60
            )
            timer.autoStartNextSession = iCloudSettings.autoStartNextSession
            AppLogger.info("Loaded timer settings from iCloud", category: .sync)
        }

        // Restore authentication state
        await authManager.restoreSession()

        // Setup timer completion handler
        timer.onSessionCompleted = { phase, duration in
            let kind: SessionRecord.Kind
            switch phase {
            case .work: kind = .work
            case .break: kind = .shortBreak
            case .longBreak: kind = .longBreak
            }
            let start = Date().addingTimeInterval(-TimeInterval(duration))
            let record = SessionRecord(startedAt: start, duration: TimeInterval(duration), kind: kind)
            // logger.add(record: record)
        }

        // Configure timer sync manager
        TimerSyncManager.shared.configure(with: timer)

        // Mark app as ready
        isAppReady = true
    }

    // MARK: - Liquid Glass Enhanced Layout Components

    #if os(iOS)
    private var mainContentView: some View {
        ZStack {
            // Background with adaptive blur
            Color.themeBackground
                .ignoresSafeArea(edges: .top)
                .blur(radius: isSidebarCollapsed ? 0 : 2)

            // Content with smooth transitions
            Group {
                switch selectedTab {
                case 0:
                    iOSContentView()
                        .transition(transitionForTab(0))
                case 1:
                    TaskManagementView()
                        .transition(transitionForTab(1))
                case 2:
                    AnalyticsView()
                        .transition(transitionForTab(2))
                case 3:
                    SettingsView()
                        .transition(transitionForTab(3))
                default:
                    iOSContentView()
                        .transition(.opacity)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTab)
            .gesture(
                DragGesture()
                    .onEnded { value in
                        handleSwipeGesture(value)
                    }
            )
        }
    }
    #endif

    #if os(iOS)
    private func transitionForTab(_ tabIndex: Int) -> AnyTransition {
        let direction = transitionDirection
        switch direction {
        case .left:
            return .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
        case .right:
            return .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
        case .up:
            return .asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top))
        case .down:
            return .asymmetric(insertion: .move(edge: .top), removal: .move(edge: .bottom))
        case .none:
            return .opacity.combined(with: .scale(scale: 0.95))
        }
    }

    private func handleSwipeGesture(_ value: DragGesture.Value) {
        let horizontalThreshold: CGFloat = 50
        let verticalThreshold: CGFloat = 100

        if abs(value.translation.width) > horizontalThreshold {
            // Horizontal swipe for tab navigation
            if value.translation.width > 0 && selectedTab > 0 {
                // Swipe right - go to previous tab
                transitionDirection = .right
                selectedTab -= 1
            } else if value.translation.width < 0 && selectedTab < 3 {
                // Swipe left - go to next tab
                transitionDirection = .left
                selectedTab += 1
            }
        } else if abs(value.translation.height) > verticalThreshold && selectedTab == 1 {
            // Vertical swipe on Tasks tab for quick actions
            if value.translation.height < 0 {
                // Swipe up - show task creation
                transitionDirection = .up
                showTaskCreation()
            }
        }

        // Reset transition direction after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            transitionDirection = .none
        }
    }

    private func showTaskCreation() {
        // This would trigger the task creation sheet
        // For now, just log the action
        print("Quick task creation triggered")
    }
    #endif
}

// MARK: - Sidebar Tab View

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
            // App logo/brand
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

            // Tab buttons with context-aware badges
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

            Spacer()

            // Quick actions at bottom
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

struct SidebarTabButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let badge: String?
    let hasActiveIndicator: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                HStack(spacing: 12) {
                    ZStack {
                        // Icon with background
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: isSelected ? .semibold : .medium))
                            .foregroundColor(iconColor)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(isSelected ? Color.themePrimary.opacity(0.15) : Color.clear)
                                    .frame(width: 40, height: 40)
                            )
                            .scaleEffect(isPressed ? 0.9 : 1.0)

                        // Active indicator
                        if hasActiveIndicator {
                            Circle()
                                .fill(Color.themePrimary)
                                .frame(width: 6, height: 6)
                                .offset(x: 14, y: -14)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(label)
                            .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                            .foregroundColor(labelColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    Spacer()
                }
                .frame(height: 50)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.themePrimary.opacity(0.08) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.themePrimary.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                        .shadow(color: isSelected ? Color.themePrimary.opacity(0.2) : Color.clear,
                               radius: isSelected ? 4 : 0, x: 0, y: 2)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Badge
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.themePrimary)
                        .clipShape(Capsule())
                        .offset(x: 8, y: -8)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .buttonStyle(.plain)
        .pressAction(onPress: { isPressed in
            withAnimation(.spring(response: 0.1, dampingFraction: 0.8)) {
                self.isPressed = isPressed
            }
        }, perform: action)
    }

    private var iconColor: Color {
        if isSelected {
            return .themePrimary
        } else if hasActiveIndicator {
            return .themePrimary.opacity(0.8)
        } else {
            return .secondary
        }
    }

    private var labelColor: Color {
        if isSelected {
            return .themePrimary
        } else if hasActiveIndicator {
            return .themePrimary.opacity(0.7)
        } else {
            return .secondary
        }
    }
}

// MARK: - Bottom Tab View

struct BottomTabView: View {
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
    let icon: String
    let label: String
    let isSelected: Bool
    let badge: String?
    let hasActiveIndicator: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 4) {
                    ZStack {
                        // Icon with background
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: isSelected ? .semibold : .medium))
                            .foregroundColor(iconColor)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(isSelected ? Color.themePrimary.opacity(0.15) : Color.clear)
                                    .frame(width: 36, height: 36)
                            )
                            .scaleEffect(isPressed ? 0.9 : 1.0)

                        // Active indicator
                        if hasActiveIndicator {
                            Circle()
                                .fill(Color.themePrimary)
                                .frame(width: 6, height: 6)
                                .offset(x: 12, y: -12)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }

                    Text(label)
                        .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(labelColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .opacity(isSelected ? 1.0 : 0.8)
                }
                .frame(height: 50)
                .padding(.vertical, 6)

                // Badge
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.themePrimary)
                        .clipShape(Capsule())
                        .offset(x: 8, y: -8)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .buttonStyle(.plain)
        .pressAction(onPress: { isPressed in
            withAnimation(.spring(response: 0.1, dampingFraction: 0.8)) {
                self.isPressed = isPressed
            }
        }, perform: action)
    }

    private var iconColor: Color {
        if isSelected {
            return .themePrimary
        } else if hasActiveIndicator {
            return .themePrimary.opacity(0.8)
        } else {
            return .secondary
        }
    }

    private var labelColor: Color {
        if isSelected {
            return .themePrimary
        } else if hasActiveIndicator {
            return .themePrimary.opacity(0.7)
        } else {
            return .secondary
        }
    }
}

// Extension for press action support
extension View {
    func pressAction(onPress: @escaping (Bool) -> Void, perform action: @escaping () -> Void) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress(true) }
                .onEnded { _ in
                    onPress(false)
                    action()
                }
        )
    }
}

// MARK: - Liquid Glass Task Management View

#if os(iOS)
struct TaskManagementView: View {
    @EnvironmentObject var taskService: TaskService
    @EnvironmentObject var timer: PomodoroTimer
    @State private var showingCreateTask = false
    @State private var showingQuickActions = false
    @State private var selectedTaskForAction: UserTask?
    @State private var isSearchActive = false
    @State private var searchText = ""

    var body: some View {
        ZStack(alignment: .top) {
            // Main content with adaptive layout
            VStack(spacing: 0) {
                // Adaptive header with search and filters
                if isSearchActive || !taskService.tasks.isEmpty {
                    AdaptiveTaskHeader(
                        searchText: $searchText,
                        isSearchActive: $isSearchActive,
                        showingCreateTask: $showingCreateTask
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Task content with smooth transitions
                ZStack {
                    if filteredTasks.isEmpty && !searchText.isEmpty {
                        // Empty search state
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("No tasks found")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Try adjusting your search")
                                .font(.subheadline)
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                        .padding(.top, 60)
                        .transition(.opacity)
                    } else if taskService.tasks.isEmpty {
                        // Empty state with onboarding
                        EmptyTaskState(showingCreateTask: $showingCreateTask)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        // Task list with enhanced interactions
                        EnhancedTaskListView(
                            tasks: filteredTasks,
                            selectedTaskForAction: $selectedTaskForAction,
                            showingQuickActions: $showingQuickActions
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading),
                            removal: .move(edge: .trailing)
                        ))
                    }
                }
            }

            // Floating action button with Liquid Glass design
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        showingCreateTask = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.themePrimary)
                                .frame(width: 56, height: 56)
                                .shadow(color: Color.themePrimary.opacity(0.3), radius: 8, x: 0, y: 4)

                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $showingCreateTask) {
            TaskCreationView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThinMaterial)
        }
        .sheet(item: $selectedTaskForAction) { task in
            TaskQuickActionsSheet(task: task)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: taskService.tasks.count)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSearchActive)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: searchText)
    }

    private var filteredTasks: [UserTask] {
        if searchText.isEmpty {
            return taskService.tasks
        } else {
            return taskService.tasks.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                (task.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }

}
#endif

// MARK: - Supporting Liquid Glass Components

struct AdaptiveTaskHeader: View {
    @Binding var searchText: String
    @Binding var isSearchActive: Bool
    @Binding var showingCreateTask: Bool
    @State private var showingRecycleBin = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Search bar with Liquid Glass design
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))

                    TextField("Search tasks...", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundColor(.primary)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.themeCardBackground.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.themePrimary.opacity(0.1), lineWidth: 1)
                        )
                )
                .frame(maxWidth: .infinity)

                // Menu with options
                Menu {
                    Button {
                        showingCreateTask = true
                    } label: {
                        Label("New Task", systemImage: "plus")
                    }

                    Button {
                        showingRecycleBin = true
                    } label: {
                        Label("Recycle Bin", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.themePrimary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color.themePrimary.opacity(0.1))
                                .overlay(
                                    Circle()
                                        .stroke(Color.themePrimary.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .background(
            Color.themeBackground.opacity(0.95)
                .blur(radius: 0.5)
                .overlay(
                    Rectangle()
                        .fill(Color.themePrimary.opacity(0.02))
                        .frame(height: 1)
                        .frame(maxWidth: .infinity, alignment: .bottom)
                )
        )
        #if os(iOS)
        .sheet(isPresented: $showingRecycleBin) {
            DeletedTasksView()
        }
        #endif
    }
}

struct EmptyTaskState: View {
    @Binding var showingCreateTask: Bool

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.themePrimary.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "checklist")
                    .font(.system(size: 48))
                    .foregroundColor(.themePrimary)
            }

            VStack(spacing: 8) {
                Text("No tasks yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("Create your first task to get started with time management")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                showingCreateTask = true
            } label: {
                Text("Create Task")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.themePrimary)
                    .clipShape(Capsule())
                    .shadow(color: Color.themePrimary.opacity(0.3), radius: 8, x: 0, y: 4)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

struct EnhancedTaskListView: View {
    let tasks: [UserTask]
    @Binding var selectedTaskForAction: UserTask?
    @Binding var showingQuickActions: Bool

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(tasks) { task in
                    EnhancedTaskRow(task: task)
                        .onTapGesture {
                            selectedTaskForAction = task
                        }
                        .onLongPressGesture {
                            showingQuickActions = true
                        }
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
        }
    }
}

struct EnhancedTaskRow: View {
    let task: UserTask
    @EnvironmentObject var taskService: TaskService
    @State private var isCompleting = false

    var body: some View {
        HStack(spacing: 16) {
            // Completion indicator with Liquid Glass design
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 32, height: 32)

                if task.status == .completed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(statusColor)
                } else {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .strikethrough(task.status == .completed)

                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .strikethrough(task.status == .completed)
                }

                HStack(spacing: 8) {
                    Text(task.status.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.1))
                        .foregroundColor(statusColor)
                        .clipShape(Capsule())

                    Text(task.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Action indicator
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.themeCardBackground.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.themePrimary.opacity(0.05), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .scaleEffect(isCompleting ? 0.95 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isCompleting)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            // Right swipe: Done & Delete
            Button {
                performDoneAndDelete()
            } label: {
                Label("Done & Delete", systemImage: "checkmark.circle.fill")
            }
            .tint(.green)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            // Left swipe: Undo (if task was recently completed)
            if task.status == .completed {
                Button {
                    performUndo()
                } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward.circle.fill")
                }
                .tint(.blue)
            }
        }
    }

    private func performDoneAndDelete() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
            isCompleting = true
        }

                    _Concurrency.Task {
            do {
                // First mark as completed, then soft delete
                _ = try await taskService.updateTask(task, status: .completed)
                try await taskService.softDeleteTask(task)
            } catch {
                AppLogger.error("Failed to complete and delete task: \(error.localizedDescription)", category: .general)
            }

            await MainActor.run {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    isCompleting = false
                }
            }
        }
    }

    private func performUndo() {
                    _Concurrency.Task {
            do {
                try await taskService.undoTaskCompletion(task)
            } catch {
                AppLogger.error("Failed to undo task completion: \(error.localizedDescription)", category: .general)
            }
        }
    }

    private var statusColor: Color {
        switch task.status {
        case .todo: return .orange
        case .inProgress: return .blue
        case .completed: return .green
        }
    }
}


struct TaskQuickActionsSheet: View {
    let task: UserTask
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var taskService: TaskService
    @EnvironmentObject var timer: PomodoroTimer

    var body: some View {
        VStack(spacing: 20) {
            // Task header
            VStack(spacing: 8) {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(.primary)

                if let description = task.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.top, 20)

            // Quick actions
            VStack(spacing: 12) {
                QuickActionButton(
                    icon: "play.circle.fill",
                    title: "Start Timer",
                    color: .themePrimary
                ) {
                    timer.currentTaskId = task.id
                    dismiss()
                }

                QuickActionButton(
                    icon: "checkmark.circle.fill",
                    title: "Mark Complete",
                    color: .green
                ) {
                    _Concurrency.Task {
                        try? await _ = taskService.updateTask(task, status: .completed)
                        dismiss()
                    }
                }

                QuickActionButton(
                    icon: "pencil",
                    title: "Edit Task",
                    color: .blue
                ) {
                    // Would navigate to edit view
                    dismiss()
                }

                QuickActionButton(
                    icon: "trash",
                    title: "Delete Task",
                    color: .red
                ) {
                    _Concurrency.Task {
                        try? await taskService.deleteTask(task)
                        dismiss()
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(Color.themeBackground.ignoresSafeArea())
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)

                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.themeCardBackground.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Deleted Tasks View

#if os(iOS)
struct DeletedTasksView: View {
    @EnvironmentObject var taskService: TaskService
    @Environment(\.dismiss) private var dismiss
    @State private var showingPermanentDeleteAlert = false
    @State private var taskToDelete: RecycleBinItem?

    var body: some View {
        NavigationView {
            ZStack {
                Color.themeBackground
                    .ignoresSafeArea()

                if taskService.getRecycleBinItems().isEmpty {
                    VStack(spacing: 24) {
                        Spacer()

                        ZStack {
                            Circle()
                                .fill(Color.themePrimary.opacity(0.1))
                                .frame(width: 120, height: 120)

                            Image(systemName: "trash.circle")
                                .font(.system(size: 48))
                                .foregroundColor(.themePrimary)
                        }

                        VStack(spacing: 8) {
                            Text("Recycle Bin is Empty")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Text("Deleted tasks will appear here for 30 days")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(taskService.getRecycleBinItems()) { item in
                                DeletedTaskRow(item: item, onRestore: {
                                    restoreTask(item)
                                }, onDelete: {
                                    taskToDelete = item
                                    showingPermanentDeleteAlert = true
                                })
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .scale(scale: 0.8).combined(with: .opacity)
                                ))
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationTitle("Recycle Bin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .alert("Permanently Delete Task?", isPresented: $showingPermanentDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete Forever", role: .destructive) {
                    if let item = taskToDelete {
                        permanentlyDeleteTask(item)
                    }
                }
            } message: {
                if let item = taskToDelete {
                    Text("This action cannot be undone. The task '\(item.task.title)' will be permanently deleted.")
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private func restoreTask(_ item: RecycleBinItem) {
                    _Concurrency.Task {
            do {
                try await taskService.restoreTask(from: item)
            } catch {
                AppLogger.error("Failed to restore task: \(error.localizedDescription)", category: .general)
            }
        }
    }

    private func permanentlyDeleteTask(_ item: RecycleBinItem) {
        // For now, just remove from recycle bin (in a real app, this would delete from backend too)
        taskService.removeFromRecycleBin(item)
    }
}
#endif

struct DeletedTaskRow: View {
    let item: RecycleBinItem
    let onRestore: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Task icon
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 32, height: 32)

                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.gray)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.task.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .strikethrough()

                if let description = item.task.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .strikethrough()
                }

                HStack(spacing: 8) {
                    Text("Deleted \(item.deletedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(item.daysUntilExpiration) days left")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .clipShape(Capsule())
                }
            }

            Spacer()

            // Action buttons
            HStack(spacing: 8) {
                Button {
                    onRestore()
                } label: {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                        .frame(width: 32, height: 32)
                }

                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                        .frame(width: 32, height: 32)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.themeCardBackground.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.themePrimary.opacity(0.05), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // App logo/icon
                Image(systemName: "timer.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color.themePrimary)

                // Loading text
                Text("TimeBeam")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color.themeTextPrimary)

                Text("Setting up your workspace...")
                    .font(.system(size: 16))
                    .foregroundColor(Color.themeTextSecondary)

                // Loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.themePrimary))
                    .scaleEffect(1.2)

                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
}

#if os(macOS)
final class MacAppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    static var shared: MacAppDelegate?
    private let notificationDelegate = NotificationDelegate()
    private static var statusItem: NSStatusItem?



    override init() {
        super.init()
        MacAppDelegate.shared = self
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self

        // Request notification permissions for macOS
        requestNotificationPermissions()

        if MacAppDelegate.statusItem == nil {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            item.button?.title = ""
            MacAppDelegate.statusItem = item
        }

        // Set up Apple Event Manager for URL handling (legacy support)
        let appleEventManager = NSAppleEventManager.shared()
        appleEventManager.setEventHandler(self, andSelector: #selector(handleURLEvent(_:replyEvent:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))

        // Ensure URL scheme registration
        registerURLScheme()
    }

    private func registerURLScheme() {
        // This helps ensure the URL scheme is properly registered
        let _ = Bundle.main.bundleIdentifier ?? "com.sparkage.time-beam"

    }

    private func isSupportedOAuthURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme else { return false }
        // Primary app scheme
        if scheme == "com.sparkage.time-beam" { return true }
        // Also allow Google-minted scheme from Info.plist (GOOGLE_REDIRECT_URI)
        if let redirect = Bundle.main.infoDictionary?["GOOGLE_REDIRECT_URI"] as? String,
           let redirectURL = URL(string: redirect),
           let redirectScheme = redirectURL.scheme,
           scheme == redirectScheme {
            return true
        }
        return false
    }

    // Handle OAuth callback URLs (modern delegate method)
    func application(_ application: NSApplication, open urls: [URL]) -> Bool {
        for url in urls {
            if isSupportedOAuthURL(url) {
                handleOAuthCallback(url)
                return true
            }
        }
        return false
    }

    // Ensure app becomes active when handling URL
    func applicationDidBecomeActive(_ notification: Notification) {
        // This ensures the app is properly activated
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func handleOAuthCallback(_ url: URL) {
        print("[Auth] handleOAuthCallback: OAuth callback received: \(url.absoluteString)")

        // Ensure app becomes active and window comes to front
        NSApplication.shared.activate(ignoringOtherApps: true)
        if let window = NSApplication.shared.mainWindow {
            window.makeKeyAndOrderFront(nil)
        }

        // Extract authorization code from URL
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems,
              let codeItem = queryItems.first(where: { $0.name == "code" }),
              let code = codeItem.value else {
            print("[Auth] handleOAuthCallback: No authorization code found")
            return
        }

        print("[Auth] handleOAuthCallback: Authorization code received: \(code.prefix(20))...")

        // Pass the authorization code to AuthManager for token exchange
        Task {
            do {
                try await AuthManager.shared.handleOAuthCallback(url)
            } catch {
                print("[Auth] OAuth callback failed: \(error)")
                // Error handled silently - logged above
            }
        }

        // Authentication completed successfully
    }

    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    AppLogger.info("Registering for remote notifications on macOS", category: .general)
                    NSApplication.shared.registerForRemoteNotifications()
                }
            } else {
                AppLogger.warning("macOS notification permission denied - bidirectional sync will not work", category: .general)
            }
            if let error = error {
                AppLogger.error("Failed to request notification permissions on macOS: \(error.localizedDescription)", category: .general)
            }
        }
    }

    // MARK: - APNs Token Registration (macOS)
    func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        AppLogger.info("Successfully registered for remote notifications on macOS, APNs token: \(tokenString.prefix(10))...", category: .general)

        // Store APNs token in Keychain for later registration
        do {
            try KeychainStore.saveString(tokenString, for: .apnsToken)
            AppLogger.info("APNs token stored in Keychain on macOS", category: .general)
        } catch {
            AppLogger.error("Failed to store APNs token in Keychain on macOS: \(error.localizedDescription)", category: .general)
        }

        // Try to register APNs token with backend if we have authentication
        _Concurrency.Task {
            AppLogger.info("Starting APN token update with backend on macOS", category: .general)
            await updateApnsTokenWithBackend(tokenString)
        }
    }

    func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        AppLogger.error("Failed to register for remote notifications on macOS: \(error.localizedDescription)", category: .general)
    }

    private func updateApnsTokenWithBackend(_ apnsToken: String) async {
        AppLogger.info("Attempting to update APN token with backend on macOS", category: .general)

        // Debug: Check access token availability
        guard let accessToken = try? KeychainStore.loadString(.accessToken) else {
            AppLogger.warning("No access token available for APNs token update on macOS", category: .general)
            return
        }



        guard let config = Configuration.fromInfoPlist() else {
            AppLogger.warning("No API config available for APNs token update on macOS", category: .general)
            return
        }

        let deviceId = await TimerSyncManager.shared.deviceId
        AppLogger.info("Got deviceId: \(deviceId), updating APN token on macOS", category: .general)
        let apiClient = ApiClient(baseURL: config.baseURL)

        // Retry logic for APN token registration
        let maxRetries = 3
        for attempt in 1...maxRetries {
            do {

                try await apiClient.updateApnsToken(deviceId: deviceId, apnsToken: apnsToken, accessToken: accessToken)
                AppLogger.info("APNs token updated with backend for macOS device: \(deviceId)", category: .general)
                return // Success, exit retry loop
            } catch {
                if attempt == maxRetries {
                    AppLogger.error("Failed to update APNs token with backend on macOS after \(maxRetries) attempts: \(error.localizedDescription)", category: .general)
                } else {
                    AppLogger.warning("APN token update attempt \(attempt) failed on macOS, retrying: \(error.localizedDescription)", category: .general)
                    // Wait before retry
                    _ = try? await Task.sleep(nanoseconds: UInt64(attempt) * 1_000_000_000) // 1, 2, 3 seconds
                }
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate (macOS)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Handle data-only (silent) notifications on macOS
        let userInfo = notification.request.content.userInfo

        if let type = userInfo["type"] as? String, type == "timer_sync" {
            AppLogger.info("Received timer sync APN message on macOS", category: .sync)

            // Parse action from notification and apply event-based sync
            if let actionDict = userInfo["action"] as? [String: Any],
               let actionType = actionDict["action"] as? String,
               let sourceDeviceId = actionDict["deviceId"] as? String,
               let timestampString = actionDict["timestamp"] as? String,
               let timestamp = Double(timestampString) {

                AppLogger.info("Processing timer action from notification: \(actionType), device: \(sourceDeviceId)", category: .sync)

                // Apply the incoming action (event-based sync)
                _Concurrency.Task {
                    await TimerSyncManager.shared.syncTimerState()
            // Don't show notification for silent sync messages
            completionHandler([])
            return
        }

        // Show regular notifications
        completionHandler([.banner, .sound])
    }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        if let type = userInfo["type"] as? String, type == "timer_sync" {
            AppLogger.info("User tapped timer sync notification on macOS", category: .sync)

            // Trigger full timer sync when user taps notification (to ensure latest state)
            _Concurrency.Task {
                await TimerSyncManager.shared.syncTimerState()
            }
        }

        completionHandler()
    }
    }

    static func updateStatusItem(title: String?) {
        DispatchQueue.main.async {
            if let title, !title.isEmpty {
                MacAppDelegate.statusItem?.button?.title = title
            } else {
                MacAppDelegate.statusItem?.button?.title = ""
            }
        }
    }

    static func showTemporaryStatus(_ message: String, duration: TimeInterval = 3.0) {
        DispatchQueue.main.async {
            let originalTitle = MacAppDelegate.statusItem?.button?.title ?? ""
            MacAppDelegate.statusItem?.button?.title = message

            // Restore original title after duration
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                MacAppDelegate.statusItem?.button?.title = originalTitle
            }
        }
    }
}
#endif

#if os(iOS)
final class iOSAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    private let notificationDelegate = NotificationDelegate()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self

        // Request notification permissions
        requestNotificationPermissions()

        return true
    }

    private func requestNotificationPermissions() {
        AppLogger.info("Requesting notification permissions on iOS", category: .general)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            AppLogger.info("iOS notification permission granted: \(granted)", category: .general)
            if granted {
                DispatchQueue.main.async {
                    AppLogger.info("Registering for remote notifications on iOS", category: .general)
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                AppLogger.warning("iOS notification permission denied - bidirectional sync will not work", category: .general)
            }
            if let error = error {
                AppLogger.error("Failed to request notification permissions on iOS: \(error.localizedDescription)", category: .general)
            }
        }
    }

    // MARK: - APNs Token Registration
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        AppLogger.info("Successfully registered for remote notifications on iOS, APNs token: \(tokenString.prefix(10))...", category: .general)

        // Store APNs token in Keychain for later registration
        do {
            try KeychainStore.saveString(tokenString, for: .apnsToken)
            AppLogger.info("APNs token stored in Keychain on iOS", category: .general)
        } catch {
            AppLogger.error("Failed to store APNs token in Keychain on iOS: \(error.localizedDescription)", category: .general)
        }

        // Try to register APNs token with backend if we have authentication
        _Concurrency.Task {
            AppLogger.info("Starting APN token update with backend on iOS", category: .general)
            await updateApnsTokenWithBackend(tokenString)
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        AppLogger.error("Failed to register for remote notifications on iOS: \(error.localizedDescription)", category: .general)
    }

    private func updateApnsTokenWithBackend(_ apnsToken: String) async {
        AppLogger.info("Attempting to update APN token with backend on iOS", category: .general)

        // Debug: Check access token availability
        guard let accessToken = try? KeychainStore.loadString(.accessToken) else {
            AppLogger.warning("No access token available for APNs token update on iOS", category: .general)
            return
        }

        guard let config = Configuration.fromInfoPlist() else {
            AppLogger.warning("No API config available for APNs token update on iOS", category: .general)
            return
        }

        let deviceId = await TimerSyncManager.shared.deviceId
        AppLogger.info("Got deviceId: \(deviceId), updating APN token on iOS", category: .general)
        let apiClient = ApiClient(baseURL: config.baseURL)

        // Retry logic for APN token registration
        let maxRetries = 3
        for attempt in 1...maxRetries {
            do {
                try await apiClient.updateApnsToken(deviceId: deviceId, apnsToken: apnsToken, accessToken: accessToken)
                AppLogger.info("APNs token updated with backend for iOS device: \(deviceId)", category: .general)
                return // Success, exit retry loop
            } catch {
                if attempt == maxRetries {
                    AppLogger.error("Failed to update APNs token with backend on iOS after \(maxRetries) attempts: \(error.localizedDescription)", category: .general)
                } else {
                    AppLogger.warning("APN token update attempt \(attempt) failed on iOS, retrying: \(error.localizedDescription)", category: .general)
                    // Wait before retry
                    _ = try? await Task.sleep(nanoseconds: UInt64(attempt) * 1_000_000_000) // 1, 2, 3 seconds
                }
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Handle data-only (silent) notifications
        let userInfo = notification.request.content.userInfo

        if let type = userInfo["type"] as? String, type == "timer_sync" {
            AppLogger.info("Received timer sync APN message on iOS", category: .sync)

            // Parse action from notification and apply event-based sync
            if let actionDict = userInfo["action"] as? [String: Any],
               let actionType = actionDict["action"] as? String,
               let sourceDeviceId = actionDict["deviceId"] as? String,
               let timestampString = actionDict["timestamp"] as? String,
               let timestamp = Double(timestampString) {

                AppLogger.info("Processing timer action from notification on iOS: \(actionType), device: \(sourceDeviceId)", category: .sync)

                // Apply the incoming action (event-based sync)
                _Concurrency.Task {
                    await TimerSyncManager.shared.syncTimerState()
                }

            // Don't show notification for silent sync messages
            completionHandler([])
            return
        }

        // Show regular notifications
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        if let type = userInfo["type"] as? String, type == "timer_sync" {
            AppLogger.info("User tapped timer sync notification on iOS", category: .sync)

            // Trigger full timer sync when user taps notification (to ensure latest state)
            _Concurrency.Task {
                await TimerSyncManager.shared.syncTimerState()
            }
        }

        completionHandler()
}
}
    }

#endif

