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