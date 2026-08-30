import SwiftData
import SwiftUI

private func weeklyReviewProjectMessage(flaggedCount: Int) -> String {
    guard flaggedCount > 0 else { return "All active projects have a next action defined" }
    let label = flaggedCount == 1 ? "project" : "projects"
    let verb = flaggedCount == 1 ? "needs" : "need"
    return String(flaggedCount) + " " + label + " " + verb + " next action defined"
}

private struct WeeklyReviewProjectStatusView: View {
    let flaggedCount: Int

    var body: some View {
        Text(weeklyReviewProjectMessage(flaggedCount: flaggedCount))
            .font(.caption.weight(.medium))
            .foregroundStyle(flaggedCount == 0 ? Color.secondary : Color.orange)
            .accessibilityIdentifier("review-projects-status")
    }
}

#if os(iOS)
struct GTDWorkspaceView: View {
    @State private var selectedTab = 0
    @State private var showingSettings = false

    var body: some View {
        TabView(selection: $selectedTab) {
            GTDHomeView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }
                .tag(0)
            GTDInboxView()
                .tabItem { Label("Inbox", systemImage: "tray.fill") }
                .tag(1)
            GTDProjectsView()
                .tabItem { Label("Projects", systemImage: "square.stack.3d.up.fill") }
                .tag(2)
            GTDFocusView()
                .tabItem { Label("Focus", systemImage: "timer") }
                .tag(3)
            GTDReviewView()
                .tabItem { Label("Review", systemImage: "checklist") }
                .tag(4)
        }
        .tint(Color.themePrimary)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingSettings = true } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
                .accessibilityIdentifier("workspace-settings")
            }
        }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .onOpenURL { url in
            if url.host == "weekly-review" { selectedTab = 4 }
        }
        .onAppear {
            let destination = UserDefaults.standard.string(forKey: SynapseModelContainer.pendingDestinationKey)
            if destination == "weekly-review" || destination == "focus" {
                selectedTab = destination == "weekly-review" ? 4 : 3
                UserDefaults.standard.removeObject(forKey: SynapseModelContainer.pendingDestinationKey)
            }
        }
    }
}

private struct GTDFocusView: View {
    var body: some View {
        NavigationStack {
            iOSContentView()
                .navigationTitle("Focus")
                .navigationBarTitleDisplayMode(.inline)
        }
        .accessibilityIdentifier("focus-tab-content")
    }
}

private struct GTDHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var tasks: [TaskItem]
    @Query(sort: \Area.createdAt) private var areas: [Area]
    @State private var showingCapture = false
    @State private var showingBriefing = false
    @State private var briefingResult: DailyBriefingResult?
    @State private var briefingCacheKey = ""
    @State private var selectedAreaID: UUID?

    private var todayTasks: [TaskItem] {
        let actions = tasks.filter { $0.status == .nextAction && ($0.dueDate == nil || Calendar.current.isDateInToday($0.dueDate!)) }
        guard let selectedAreaID, let area = areas.first(where: { $0.id == selectedAreaID }) else { return actions }
        return GTDWorkspaceMetrics.tasks(in: area, from: actions)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(greeting)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                        Text("Make space for what matters.")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .tracking(-0.6)
                    }

                    Button { showingCapture = true } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "plus")
                                .font(.headline.weight(.bold))
                                .frame(width: 38, height: 38)
                                .foregroundStyle(Color.themeTextPrimary)
                                .background(Color.themeTextPrimary.opacity(0.10), in: Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Capture an idea")
                                    .font(.headline.weight(.semibold))
                                Text("Get it out of your head")
                                    .font(.caption)
                                    .foregroundStyle(Color.themeTextPrimary.opacity(0.72))
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.themeTextPrimary.opacity(0.72))
                        }
                        .foregroundStyle(Color.themeTextPrimary)
                        .padding(16)
                        .background(Color.themeAccent, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Capture an idea")
                    .accessibilityIdentifier(
                        SynapseModelContainer.isTestingProcess
                            ? "home-capture-ui-testing"
                            : "home-capture-button"
                    )

                    GTDAreaFilterChips(areas: areas, selection: $selectedAreaID)

                    HStack(spacing: 12) {
                        GTDMetric(title: "Inbox", value: tasks.filter { $0.status == .inbox }.count, tint: .orange)
                        GTDMetric(title: "Next actions", value: todayTasks.count, tint: .blue)
                        GTDMetric(title: "Waiting", value: tasks.filter { $0.status == .waitingFor }.count, tint: .purple)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Today")
                                .font(.title3.weight(.bold))
                            Spacer()
                            Text("\(todayTasks.count) actions")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }

                        if todayTasks.isEmpty {
                            GTDEmptyState(icon: "sparkles", title: "Your day is clear", message: "Capture something new or enjoy the space.")
                        } else {
                            ForEach(todayTasks.prefix(5)) { task in
                                GTDTaskRow(task: task)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.themeBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            let key = briefingKey
                            if briefingCacheKey != key {
                                briefingResult = await DailyBriefingService.shared.makeBriefing(
                                    tasks: tasks,
                                    isFirstRun: tasks.isEmpty && !UserDefaults.standard.bool(forKey: "synapse.hasGeneratedBriefing")
                                )
                                briefingCacheKey = key
                                UserDefaults.standard.set(true, forKey: "synapse.hasGeneratedBriefing")
                            }
                            showingBriefing = true
                        }
                    } label: { Image(systemName: "sparkles") }
                    .accessibilityLabel("Generate daily briefing")
                    .accessibilityIdentifier("daily-briefing-button")
                }
            }
            .sheet(isPresented: $showingCapture) { GTDCaptureSheet(defaultStatus: .inbox) }
            .sheet(isPresented: $showingBriefing) {
                if let briefingResult {
                    DailyBriefingView(result: briefingResult)
                }
            }
        }
    }

    private var briefingKey: String {
        let day = Calendar.current.startOfDay(for: .now).timeIntervalSince1970
        let taskState = tasks.map {
            "\($0.id.uuidString):\($0.statusRawValue):\($0.dueDate?.timeIntervalSince1970 ?? 0):\($0.updatedAt.timeIntervalSince1970)"
        }.joined(separator: "|")
        return "\(day)|\(DailyBriefingService.shared.calendarAccessCacheKey)|\(taskState)"
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        return hour < 12 ? "Good morning" : hour < 18 ? "Good afternoon" : "Good evening"
    }
}

private struct DailyBriefingView: View {
    let result: DailyBriefingResult

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if result.sections.isFirstRun {
                        emptyCard(icon: "sparkles", title: "Start with a thought", message: result.plainText)
                    } else if !result.sections.hasWork {
                        emptyCard(icon: "checkmark.seal.fill", title: "All clear", message: result.plainText)
                    } else {
                        if let narrative = result.narrative {
                            Text(narrative)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(Color.themeTextPrimary)
                                .padding(16)
                                .background(Color.themeAccent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        if !result.sections.dueToday.isEmpty { itemSection("Due today", icon: "sun.max.fill", items: result.sections.dueToday, tint: .blue) }
                        if !result.sections.overdue.isEmpty { itemSection("Overdue", icon: "exclamationmark.triangle.fill", items: result.sections.overdue, tint: .orange) }
                        if !result.sections.waiting.isEmpty { itemSection("Check on this", icon: "clock.badge.questionmark", items: result.sections.waiting, tint: .purple) }
                        calendarSection
                    }
                }
                .padding(20)
            }
            .background(Color.themeBackground.ignoresSafeArea())
            .navigationTitle("Daily briefing")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func emptyCard(icon: String, title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon).font(.title2).foregroundStyle(Color.themePrimary)
            Text(title).font(.title3.weight(.bold))
            Text(message).font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.themeCardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func itemSection(_ title: String, icon: String, items: [DailyBriefingItem], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon).font(.headline).foregroundStyle(tint)
            ForEach(items) { item in
                HStack(spacing: 10) {
                    Circle().fill(tint.opacity(0.18)).frame(width: 28, height: 28).overlay { Image(systemName: "circle").font(.caption).foregroundStyle(tint) }
                    Text(item.title).font(.subheadline.weight(.medium))
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(Color.themeCardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var calendarSection: some View {
        let events = result.sections.calendarEvents
        guard !events.isEmpty else { return AnyView(EmptyView()) }
        let allDay = events.filter(\.isAllDay)
        let timed = events.filter { !$0.isAllDay }
        return AnyView(VStack(alignment: .leading, spacing: 10) {
            Label("Calendar", systemImage: "calendar").font(.headline).foregroundStyle(.green)
            if events.count >= 8 { Text("Packed day — \(events.count) meetings").font(.subheadline.weight(.medium)) }
            if !allDay.isEmpty { Text("All day: \(allDay.map(\.title).joined(separator: ", "))").font(.subheadline) }
            ForEach(timed) { event in
                Text("\(event.startDate, style: .time)  \(event.title)").font(.subheadline)
            }
        }.padding(16).background(Color.themeCardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous)))
    }
}

private struct GTDMetric: View {
    let title: String
    let value: Int
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Circle().fill(tint).frame(width: 8, height: 8)
            Text("\(value)").font(.title2.weight(.bold).monospacedDigit())
            Text(title).font(.caption).foregroundStyle(.secondary).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.themeCardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct GTDInboxView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var tasks: [TaskItem]
    @Query(sort: \Area.createdAt) private var areas: [Area]
    @State private var searchText = ""
    @State private var showingCapture = false
    @State private var isTriaging = false
    @State private var triageNotice = ""
    @State private var showingTriageNotice = false
    @State private var triagedTaskIDs: [UUID] = []
    @State private var showingTriageResults = false
    @State private var selectedAreaID: UUID?

    private var inboxTasks: [TaskItem] { tasks.filter { $0.status == .inbox } }
    private var visibleTasks: [TaskItem] {
        let searched = GTDInboxBehavior.filteredTasks(inboxTasks, query: searchText)
        guard let selectedAreaID, let area = areas.first(where: { $0.id == selectedAreaID }) else { return searched }
        return GTDWorkspaceMetrics.tasks(in: area, from: searched)
    }
    private var triagedTasks: [TaskItem] { tasks.filter { triagedTaskIDs.contains($0.id) } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    inboxHeader
                    GTDInboxSearchField(text: $searchText)
                    GTDAreaFilterChips(areas: areas, selection: $selectedAreaID)
                    captureCard
                    triageCard
                    NavigationLink { GTDTaskListsView() } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "rectangle.3.group.fill")
                                .foregroundStyle(Color.themePrimary)
                                .frame(width: 34, height: 34)
                                .background(Color.themePrimary.opacity(0.12), in: Circle())
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Browse GTD lists").font(.subheadline.weight(.semibold))
                                Text("Next Actions, Waiting For, and Someday / Maybe")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(.tertiary)
                        }
                        .padding(14)
                        .background(Color.themeCardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("browse-gtd-lists")
                if visibleTasks.isEmpty {
                    GTDEmptyState(icon: searchText.isEmpty ? "tray" : "magnifyingglass", title: searchText.isEmpty ? "Inbox is clear" : "No matching captures", message: searchText.isEmpty ? "A quiet mind starts with one small capture." : "Try a different word or clear your search.")
                        .padding(.top, 8)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(searchText.isEmpty ? "To process" : "Results")
                                .font(.title3.weight(.bold))
                            Spacer()
                            Text("\(visibleTasks.count)")
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        LazyVStack(spacing: 10) {
                            ForEach(visibleTasks) { task in
                                GTDInboxCard(task: task)
                                    .contextMenu {
                                        Button { task.status = .nextAction; try? modelContext.save() } label: {
                                            Label("Make next action", systemImage: "arrow.right.circle")
                                        }
                                        Button(role: .destructive) { modelContext.delete(task); try? modelContext.save() } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color.themeBackground.ignoresSafeArea())
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingCapture = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Capture a thought")
                }
            }
            .sheet(isPresented: $showingCapture) { GTDCaptureSheet(defaultStatus: .inbox) }
            .sheet(isPresented: $showingTriageResults) { GTDTriageResultsSheet(tasks: triagedTasks) }
            .alert("Inbox triaged", isPresented: $showingTriageNotice) { Button("Done") {} } message: { Text(triageNotice) }
        }
    }

    private var inboxHeader: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Clear your head")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .tracking(-0.6)
                Text("Everything here is waiting for a decision.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(inboxTasks.count)")
                    .font(.system(size: 27, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Color.themePrimary)
                Text(inboxTasks.count == 1 ? "capture" : "captures")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(inboxTasks.count) inbox captures")
        }
    }

    private var captureCard: some View {
        Button { showingCapture = true } label: {
            HStack(spacing: 13) {
                Image(systemName: "plus")
                    .font(.headline.weight(.bold))
                    .frame(width: 40, height: 40)
                    .foregroundStyle(Color.themeTextPrimary)
                    .background(Color.themeTextPrimary.opacity(0.10), in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text("Capture a thought").font(.headline.weight(.semibold))
                    Text("Get it out of your head in one tap")
                        .font(.caption)
                        .foregroundStyle(Color.themeTextPrimary.opacity(0.72))
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.themeTextPrimary.opacity(0.72))
            }
            .foregroundStyle(Color.themeTextPrimary)
            .padding(16)
            .background(Color.themeAccent, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("inbox-capture-button")
    }

    private var triageCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .foregroundStyle(Color.themePrimary)
                .frame(width: 34, height: 34)
                .background(Color.themePrimary.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text("Ready to sort it out?").font(.subheadline.weight(.semibold))
                Text("Let on-device intelligence suggest what comes next.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button { Task { await triageInbox() } } label: {
                if isTriaging { ProgressView() } else { Text("Triage").font(.subheadline.weight(.semibold)) }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.themePrimary)
            .disabled(isTriaging || inboxTasks.isEmpty)
            .accessibilityIdentifier("inbox-triage-button")
        }
        .padding(14)
        .background(Color.themeCardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func triageInbox() async {
        isTriaging = true
        let movedTasks = await InboxTriageService.triage(inboxTasks)
        try? modelContext.save()
        isTriaging = false
        triageNotice = GTDInboxBehavior.triageSummary(movedCount: movedTasks.count)
        triagedTaskIDs = movedTasks.map(\.id)
        if movedTasks.isEmpty {
            showingTriageNotice = true
        } else {
            showingTriageResults = true
        }
    }
}

private struct GTDInboxSearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search captures", text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .accessibilityIdentifier("Search captures")
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .background(Color.themeCardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.themeBorder, lineWidth: 1)
        }
    }
}

private struct GTDInboxCard: View {
    let task: TaskItem

    var body: some View {
        NavigationLink { GTDTaskDetailView(task: task) } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "circle")
                    .font(.title3)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 1)
                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    if !task.notes.isEmpty {
                        Text(task.notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    HStack(spacing: 6) {
                        Text("Captured \(task.createdAt, style: .date)")
                        if let dueDate = task.dueDate {
                            Text("•")
                            Text("Due \(dueDate, style: .date)")
                        }
                    }
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }
            .padding(15)
            .background(Color.themeCardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("inbox-item-\(task.id.uuidString)")
    }
}

private struct GTDTriageResultsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let tasks: [TaskItem]

    private let statuses: [GTDStatus] = [.nextAction, .waitingFor, .somedayMaybe]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("Nothing was deleted. Each capture now has a GTD home.", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ForEach(statuses, id: \.self) { status in
                    let matchingTasks = GTDInboxBehavior.organizedTasks(tasks, status: status)
                    if !matchingTasks.isEmpty {
                        Section(status.displayName) {
                            ForEach(matchingTasks) { task in
                                NavigationLink { GTDTaskDetailView(task: task) } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(task.title).font(.body.weight(.medium))
                                        if let dueDate = task.dueDate {
                                            Text("Due \(dueDate, style: .date)")
                                                .font(.caption).foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .accessibilityIdentifier("triage-result-\(status.rawValue)-\(task.id.uuidString)")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sorted for you")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    NavigationLink("All lists") { GTDTaskListsView() }
                        .accessibilityIdentifier("triage-results-all-lists")
                }
            }
        }
    }
}

private struct GTDTaskListsView: View {
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var tasks: [TaskItem]
    @State private var selectedStatus: GTDStatus

    private let statuses: [GTDStatus] = [.nextAction, .waitingFor, .somedayMaybe]

    init(initialStatus: GTDStatus = .nextAction) {
        _selectedStatus = State(initialValue: initialStatus)
    }

    private var visibleTasks: [TaskItem] {
        GTDInboxBehavior.organizedTasks(tasks, status: selectedStatus)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("ORGANIZED WORK").font(.caption.weight(.bold)).foregroundStyle(Color.themePrimary)
                    Text(selectedStatus.displayName).font(.system(size: 30, weight: .bold, design: .rounded)).tracking(-0.6)
                    Text(listDescription).font(.subheadline).foregroundStyle(.secondary)
                }

                Picker("GTD list", selection: $selectedStatus) {
                    Text("Next").tag(GTDStatus.nextAction)
                    Text("Waiting").tag(GTDStatus.waitingFor)
                    Text("Someday").tag(GTDStatus.somedayMaybe)
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("gtd-list-picker")

                if visibleTasks.isEmpty {
                    GTDEmptyState(icon: emptySymbol, title: "Nothing here yet", message: emptyMessage)
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(visibleTasks) { task in
                            GTDTaskRow(task: task)
                                .padding(.horizontal, 4)
                                .accessibilityIdentifier("gtd-list-\(selectedStatus.rawValue)-\(task.id.uuidString)")
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Color.themeBackground.ignoresSafeArea())
        .navigationTitle("GTD Lists")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var listDescription: String {
        switch selectedStatus {
        case .nextAction: "Every actionable step, including work scheduled for later."
        case .waitingFor: "Promises, replies, and outcomes you are waiting on."
        case .somedayMaybe: "Ideas worth keeping without making a commitment today."
        default: ""
        }
    }

    private var emptySymbol: String {
        switch selectedStatus {
        case .nextAction: "checklist"
        case .waitingFor: "hourglass"
        case .somedayMaybe: "sparkles"
        default: "tray"
        }
    }

    private var emptyMessage: String {
        switch selectedStatus {
        case .nextAction: "Clarify an Inbox capture or add an action directly."
        case .waitingFor: "Move a capture here when someone else has the next move."
        case .somedayMaybe: "Keep an idea here until it becomes a real commitment."
        default: ""
        }
    }
}

private struct GTDProjectsView: View {
    @Query(sort: \Project.createdAt, order: .reverse) private var projects: [Project]
    @Query private var tasks: [TaskItem]
    @Query(sort: \Area.createdAt) private var areas: [Area]
    @State private var showingNewProject = false
    @State private var filter: GTDWorkspaceFilter = .active
    @State private var selectedAreaID: UUID?

    private var visibleProjects: [Project] {
        let filtered = GTDWorkspaceMetrics.projects(projects, matching: filter)
        guard let selectedAreaID, let area = areas.first(where: { $0.id == selectedAreaID }) else { return filtered }
        return filtered.filter { project in
            !GTDWorkspaceMetrics.tasks(in: area, from: tasks.filter { $0.project?.id == project.id }).isEmpty
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    GTDCollectionHeader(eyebrow: "OUTCOMES", title: "Projects", message: "Turn multi-step commitments into clear, finishable outcomes.", symbol: "square.stack.3d.up.fill", tint: Color.themePrimary)
                    GTDAreaFilterChips(areas: areas, selection: $selectedAreaID)
                    HStack(spacing: 10) {
                        GTDCollectionStat(value: projects.filter { !$0.isArchived && $0.status == .active }.count, label: "Active", tint: Color.themePrimary)
                        GTDCollectionStat(value: projects.filter { !$0.isArchived && $0.status == .completed }.count, label: "Completed", tint: .secondary)
                    }
                    GTDWorkspacePicker(selection: $filter)
                    if visibleProjects.isEmpty {
                        GTDEmptyState(
                            icon: filter == .active ? "sparkles" : filter == .completed ? "checkmark.circle" : "archivebox",
                            title: filter == .active ? "Nothing active yet" : filter == .completed ? "No completed projects" : "No archived projects",
                            message: filter == .active ? "Give your next outcome a home." : filter == .completed ? "Finished outcomes will appear here." : "Archived outcomes will appear here when you set one aside."
                        )
                            .padding(.top, 16)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(visibleProjects) { project in
                                NavigationLink { GTDProjectDetailView(project: project, tasks: tasks) } label: {
                                    GTDProjectCard(project: project, tasks: tasks)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("project-card-\(project.id.uuidString)")
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.themeBackground.ignoresSafeArea())
            .navigationTitle("Projects")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) {
                Button { showingNewProject = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add project")
                    .accessibilityIdentifier("add-project")
            } }
            .sheet(isPresented: $showingNewProject) { GTDNewProjectSheet() }
        }
    }
}

private struct GTDAreasView: View {
    @Query(sort: \Area.createdAt) private var areas: [Area]
    @Query private var tasks: [TaskItem]
    @State private var showingNewArea = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    GTDCollectionHeader(eyebrow: "RESPONSIBILITIES", title: "Areas", message: "Keep the parts of life that never truly leave your care in view.", symbol: "circle.grid.2x2.fill", tint: Color(red: 0.91, green: 0.43, blue: 0.27))
                    if areas.isEmpty {
                        GTDEmptyState(icon: "circle.grid.2x2", title: "No areas yet", message: "Add a responsibility you want to keep healthy.").padding(.top, 16)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(areas) { area in
                                NavigationLink { GTDAreaDetailView(area: area, tasks: tasks) } label: {
                                    GTDAreaCard(area: area, tasks: GTDWorkspaceMetrics.tasks(in: area, from: tasks))
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("area-card-\(area.id.uuidString)")
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.themeBackground.ignoresSafeArea())
            .navigationTitle("Areas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) {
                Button { showingNewArea = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add area")
                    .accessibilityIdentifier("add-area")
            } }
            .sheet(isPresented: $showingNewArea) { GTDNewAreaSheet() }
        }
    }
}

private struct GTDCollectionHeader: View {
    let eyebrow: String; let title: String; let message: String; let symbol: String; let tint: Color
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol).font(.title3.weight(.semibold)).foregroundStyle(tint)
                .frame(width: 46, height: 46).background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            VStack(alignment: .leading, spacing: 5) {
                Text(eyebrow).font(.caption.weight(.bold)).tracking(1.2).foregroundStyle(tint)
                Text(title).font(.system(size: 30, weight: .bold, design: .rounded)).tracking(-0.6)
                Text(message).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }.accessibilityElement(children: .combine)
    }
}

private struct GTDCollectionStat: View {
    let value: Int; let label: String; let tint: Color
    var body: some View { VStack(alignment: .leading, spacing: 4) { Text("\(value)").font(.title2.weight(.bold).monospacedDigit()).foregroundStyle(tint); Text(label).font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading).padding(14).background(Color.themeCardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous)) }
}

private struct GTDWorkspacePicker: View {
    @Binding var selection: GTDWorkspaceFilter
    var body: some View {
        HStack(spacing: 4) { ForEach(GTDWorkspaceFilter.allCases) { filter in
            Button { withAnimation(.easeOut(duration: 0.18)) { selection = filter } } label: { Text(filter.title).font(.subheadline.weight(.semibold)).foregroundStyle(selection == filter ? .primary : .secondary).frame(maxWidth: .infinity).padding(.vertical, 10).background(selection == filter ? Color.themeCardBackground : .clear, in: Capsule()) }.buttonStyle(.plain).accessibilityIdentifier("workspace-filter-\(filter.rawValue)")
        }}.padding(4).background(Color.themeCardBackground.opacity(0.62), in: Capsule())
    }
}

private struct GTDAreaFilterChips: View {
    let areas: [Area]
    @Binding var selection: UUID?

    var body: some View {
        if !areas.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterButton(title: "All areas", symbol: "line.3.horizontal.decrease.circle") {
                        selection = nil
                    }
                    ForEach(areas) { area in
                        filterButton(title: area.name, symbol: "circle.fill", isSelected: selection == area.id) {
                            selection = area.id
                        }
                    }
                }
            }
            .accessibilityIdentifier("area-filter-chips")
        }
    }

    private func filterButton(title: String, symbol: String, isSelected: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? Color.themeTextPrimary : .secondary)
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .background(isSelected ? Color.themePrimary.opacity(0.22) : Color.themeCardBackground, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Filter by \(title)")
    }
}

private struct GTDProjectCard: View {
    let project: Project; let tasks: [TaskItem]
    private var projectTasks: [TaskItem] { tasks.filter { $0.project?.id == project.id } }
    private var metrics: GTDProjectMetrics { GTDWorkspaceMetrics.projectMetrics(tasks: projectTasks) }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) { VStack(alignment: .leading, spacing: 5) { Text(project.title).font(.headline); Text(project.desiredOutcome.isEmpty ? "Outcome not defined" : project.desiredOutcome).font(.subheadline).foregroundStyle(.secondary).lineLimit(2) }; Spacer(); Image(systemName: "arrow.up.right").font(.caption.weight(.bold)).foregroundStyle(.secondary) }
            ProgressView(value: metrics.progress).tint(project.status == .completed ? .secondary : Color.themePrimary).accessibilityIdentifier("project-progress-\(project.id.uuidString)")
            HStack { Label("\(metrics.completed)/\(metrics.total) done", systemImage: "checkmark.circle"); Spacer(); Text(project.status == .completed ? "Complete" : "\(metrics.remaining) remaining") }.font(.caption.weight(.medium)).foregroundStyle(.secondary)
        }.padding(16).background(Color.themeCardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous)).contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct GTDAreaCard: View {
    let area: Area; let tasks: [TaskItem]
    var body: some View { HStack(spacing: 14) { Circle().fill(Color.orange.opacity(0.14)).frame(width: 44, height: 44).overlay(Image(systemName: "circle.grid.2x2.fill").font(.subheadline).foregroundStyle(.orange)); VStack(alignment: .leading, spacing: 4) { Text(area.name).font(.headline); Text(area.notes.isEmpty ? "Ongoing responsibility" : area.notes).font(.caption).foregroundStyle(.secondary).lineLimit(1) }; Spacer(); VStack(alignment: .trailing, spacing: 3) { Text("\(tasks.filter { $0.status != .completed }.count)").font(.title3.weight(.bold).monospacedDigit()); Text("open").font(.caption2).foregroundStyle(.secondary) } }.padding(16).background(Color.themeCardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous)).contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous)) }
}

private struct GTDProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let project: Project
    let tasks: [TaskItem]
    @State private var showingCompletionWarning = false
    @State private var showingArchiveConfirmation = false

    private var projectTasks: [TaskItem] { tasks.filter { $0.project?.id == project.id } }

    var body: some View {
        List {
            Section {
                Text(project.desiredOutcome.isEmpty ? "Define the outcome this project is moving toward." : project.desiredOutcome)
                    .font(.subheadline).foregroundStyle(.secondary)
                ProgressView(value: GTDWorkspaceMetrics.projectMetrics(tasks: projectTasks).progress)
                    .accessibilityIdentifier("project-detail-progress")
            } header: { Text("Outcome") }
            Section("Actions") {
                if projectTasks.isEmpty { Text("No actions yet").foregroundStyle(.secondary) }
                ForEach(projectTasks) { task in
                    Button {
                        task.status = task.status == .completed ? .nextAction : .completed
                        try? modelContext.save()
                    } label: {
                        Label(task.title, systemImage: task.status == .completed ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(task.status == .completed ? .secondary : .primary)
                    }
                    .accessibilityIdentifier("project-task-\(task.id.uuidString)")
                }
            }
            if !project.isArchived {
                Section {
                    Button(project.status == .completed ? "Reopen project" : "Complete project") {
                        if project.status != .completed && !WeeklyReviewService.shared.canComplete(project) {
                            showingCompletionWarning = true
                        } else {
                            project.status = project.status == .completed ? .active : .completed
                            try? modelContext.save()
                        }
                    }
                    .foregroundStyle(project.status == .completed ? .primary : Color.themePrimary)
                    .accessibilityIdentifier("project-completion-action")
                }
            }
        }
        .navigationTitle(project.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if project.isArchived {
                        Button("Restore project", systemImage: "arrow.uturn.backward") {
                            project.restore()
                            try? modelContext.save()
                        }
                        .accessibilityIdentifier("restore-project")
                    } else {
                        Button("Archive project", systemImage: "archivebox") {
                            showingArchiveConfirmation = true
                        }
                        .accessibilityIdentifier("archive-project")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Project actions")
                .accessibilityIdentifier("project-actions-menu")
            }
        }
        .alert("Open actions remain", isPresented: $showingCompletionWarning) {
            Button("Keep working", role: .cancel) { }
        } message: {
            Text("Complete or reassign all Next Action and Waiting For tasks before completing this project.")
        }
        .alert("Archive project?", isPresented: $showingArchiveConfirmation) {
            Button("Archive project", role: .destructive) {
                project.archive()
                try? modelContext.save()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(projectTasks.isEmpty ? "This empty project will be hidden until you restore it." : "Its linked actions will stay attached and can be restored with the project.")
        }
    }
}

private struct GTDAreaDetailView: View {
    let area: Area
    let tasks: [TaskItem]

    private var openTasks: [TaskItem] { GTDWorkspaceMetrics.openTasks(in: area, from: tasks) }

    var body: some View {
        List {
            Section {
                Text(area.notes.isEmpty ? "An ongoing responsibility to keep healthy." : area.notes)
                    .font(.subheadline).foregroundStyle(.secondary)
            } header: { Text("Responsibility") }
            Section("Open actions") {
                if openTasks.isEmpty { Text("This area is clear").foregroundStyle(.secondary) }
                ForEach(openTasks) { task in
                    Label(task.title, systemImage: "circle")
                        .accessibilityIdentifier("area-task-\(task.id.uuidString)")
                }
            }
        }
        .navigationTitle(area.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct GTDReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeeklyReview.weekStart, order: .reverse) private var reviews: [WeeklyReview]
    @Query private var tasks: [TaskItem]
    @Query private var projects: [Project]
    @Query(sort: \Area.createdAt) private var areas: [Area]
    @State private var review: WeeklyReview?
    @State private var reviewPrompt = ""
    @State private var showingReviewPrompt = false

    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                    Text("A weekly reset for a clearer mind.")
                        .font(.title2.weight(.bold))
                    Text("Review your commitments, close open loops, and start the next week with confidence.")
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        GTDReviewStat(value: reviews.filter { $0.status == .completed }.count, label: "Reviews completed", tint: Color.themePrimary)
                        GTDReviewStat(value: tasks.filter { $0.status == .waitingFor }.count, label: "Waiting on", tint: .purple)
                        GTDReviewStat(value: WeeklyReviewService.shared.reviewStreak(reviews), label: "Current streak", tint: .orange)
                    }

                    if let review {
                        HStack {
                            Text(review.status == .inProgress ? "Review in progress" : review.status == .partial ? "Partial review" : "Review complete")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("\(review.completedStepCount + review.skippedStepCount)/\(review.checklistItems?.count ?? 6) steps")
                                .font(.caption.weight(.medium)).foregroundStyle(.secondary)
                        }
                        .accessibilityIdentifier("weekly-review-progress")
                        VStack(spacing: 0) {
                            ForEach((review.checklistItems ?? []).sorted { $0.sortOrder < $1.sortOrder }) { item in
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(alignment: .top, spacing: 14) {
                                        Image(systemName: item.isComplete ? "checkmark.circle.fill" : item.isSkipped ? "arrow.forward.circle" : "circle")
                                            .font(.title3).foregroundStyle(item.isComplete ? Color.themePrimary : item.isSkipped ? .orange : .secondary)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.title).font(.headline).foregroundStyle(.primary)
                                            Text(item.instructions).font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        let stepLabel = "\(item.sortOrder + 1)/6"
                                        Text(stepLabel).font(.caption2.weight(.bold)).foregroundStyle(.tertiary)
                                    }
                                    HStack(spacing: 10) {
                                        Button(item.isComplete || item.isSkipped ? "Saved" : "Complete") {
                                            advance(review, item: item, skipped: false)
                                        }
                                        .buttonStyle(.borderedProminent).tint(Color.themePrimary)
                                        .disabled(item.isComplete || item.isSkipped)
                                        .accessibilityIdentifier("complete-review-step-\(item.sortOrder)")
                                        Button("Skip") {
                                            advance(review, item: item, skipped: true)
                                        }
                                        .buttonStyle(.bordered).disabled(item.isComplete || item.isSkipped)
                                        .accessibilityIdentifier("skip-review-step-\(item.sortOrder)")
                                    }
                                    if item.kind == .stale {
                                        let staleTasks = tasks.filter { review.staleTaskIDs.contains($0.id.uuidString) }
                                        if staleTasks.isEmpty {
                                            Text("Nothing stale").font(.caption.weight(.medium)).foregroundStyle(.secondary)
                                                .accessibilityIdentifier("review-no-stale-items")
                                        } else {
                                            ForEach(staleTasks) { task in
                                                HStack {
                                                    Text(task.title).font(.caption).lineLimit(1)
                                                    Spacer()
                                                    Menu("Decide") {
                                                        Button("Promote to Next Action") { WeeklyReviewService.shared.decide(.promote, for: task, review: review); try? modelContext.save() }
                                                        Button("Keep") { WeeklyReviewService.shared.decide(.keep, for: task, review: review); try? modelContext.save() }
                                                        Button("Delete", role: .destructive) { WeeklyReviewService.shared.decide(.delete, for: task, review: review); try? modelContext.save() }
                                                    }
                                                    .accessibilityIdentifier("stale-decision-\(task.id.uuidString)")
                                                }
                                            }
                                        }
                                    }
                                    if item.kind == .organize {
                                        let flagged = WeeklyReviewService.shared.projectsNeedingNextAction(projects)
                                        WeeklyReviewProjectStatusView(flaggedCount: flagged.count)
                                    }
                                }
                                .padding(16)
                                .accessibilityIdentifier("weekly-review-step-" + String(item.sortOrder))
                                if item.id != (review.checklistItems ?? []).last?.id { Divider().padding(.leading, 54) }
                            }
                        }
                        .background(Color.themeCardBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        if review.status != .inProgress {
                            Button("Start a new review") { startReview() }
                                .font(.headline).foregroundStyle(.white).frame(maxWidth: .infinity)
                                .padding(.vertical, 15).background(Color.themePrimary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .accessibilityIdentifier("start-new-weekly-review")
                        }
                    } else {
                        Button("Start weekly review") { startReview() }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.themePrimary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .accessibilityIdentifier("start-weekly-review")
                    }

                    NavigationLink { GTDAreasView() } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "circle.grid.2x2.fill")
                                .foregroundStyle(.orange)
                                .frame(width: 36, height: 36)
                                .background(Color.orange.opacity(0.12), in: Circle())
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Areas of focus").font(.subheadline.weight(.semibold))
                                Text("Filter Work, Personal, Health, and more")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(areas.count)").font(.headline.monospacedDigit()).foregroundStyle(.secondary)
                            Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(.tertiary)
                        }
                        .padding(14)
                        .background(Color.themeCardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("review-areas-overview")
                }
                    .padding(20)
                }
                .onChange(of: review?.currentStep) { _, step in
                    guard let step else { return }
                    let scroll = {
                        scrollProxy.scrollTo("weekly-review-step-\(step)", anchor: .center)
                    }
                    if ProcessInfo.processInfo.arguments.contains("-ui-testing") {
                        scroll()
                    } else {
                        withAnimation(.easeOut(duration: 0.2), scroll)
                    }
                }
            }
            .background(Color.themeBackground.ignoresSafeArea())
            .navigationTitle("Weekly Review")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        guard let review else { return }
                        Task {
                            reviewPrompt = await OnDeviceIntelligenceService.shared.weeklyReviewPrompt(review: review, openTaskCount: tasks.filter { $0.status != .completed && $0.status != .cancelled }.count)
                            showingReviewPrompt = true
                        }
                    } label: { Image(systemName: "sparkles") }
                    .disabled(review == nil)
                    .accessibilityLabel("Get a weekly review prompt")
                }
            }
            .alert("Review prompt", isPresented: $showingReviewPrompt) { Button("Done") {} } message: { Text(reviewPrompt) }
            .onAppear {
                let resumedReview = WeeklyReviewService.shared.resumeReview(from: reviews)
                let completedReview = reviews.first { candidate in
                    let isCompleted = candidate.status == .completed
                    let isPartial = candidate.status == .partial
                    return isCompleted || isPartial
                }
                if let resumedReview {
                    review = resumedReview
                } else {
                    review = completedReview
                }
                if let review, review.status == .inProgress { WeeklyReviewService.shared.prepareStaleItems(tasks, for: review); try? modelContext.save() }
            }
        }
    }

    private func startReview() {
        let newReview = WeeklyReviewService.shared.makeWeeklyReview()
        modelContext.insert(newReview)
        try? modelContext.save()
        review = newReview
    }

    private func advance(_ review: WeeklyReview, item: WeeklyReviewItem, skipped: Bool) {
        WeeklyReviewService.shared.saveStep(review, step: item.sortOrder, skipped: skipped)
        if review.status != .inProgress {
            WeeklyReviewService.shared.finish(review, reviews: reviews.filter { $0.id != review.id })
        }
        try? modelContext.save()
    }
}

private struct GTDReviewStat: View {
    let value: Int
    let label: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("\(value)").font(.title2.weight(.bold).monospacedDigit()).foregroundStyle(tint)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.themeCardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct GTDTaskRow: View {
    @Environment(\.modelContext) private var modelContext
    let task: TaskItem

    var body: some View {
        HStack(spacing: 13) {
            Button {
                task.status = .completed
                try? modelContext.save()
            } label: {
                Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.status == .completed ? Color.themePrimary : .secondary)
            }
            .buttonStyle(.plain)

            NavigationLink {
                GTDTaskDetailView(task: task)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.body.weight(.medium))
                        .strikethrough(task.status == .completed)
                        .accessibilityIdentifier("task-title-\(task.title)")
                    if !task.notes.isEmpty {
                        Text(task.notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if let dueDate = task.dueDate {
                    Text(dueDate, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityIdentifier("task-row-\(task.id.uuidString)")
        }
        .padding(.vertical, 6)
    }
}

private struct GTDTaskDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let task: TaskItem
    @State private var title: String
    @State private var notes: String
    @State private var status: GTDStatus
    @State private var hasDueDate: Bool
    @State private var dueDate: Date

    init(task: TaskItem) {
        self.task = task
        _title = State(initialValue: task.title)
        _notes = State(initialValue: task.notes)
        _status = State(initialValue: task.status)
        _hasDueDate = State(initialValue: task.dueDate != nil)
        _dueDate = State(initialValue: task.dueDate ?? .now)
    }

    var body: some View {
        Form {
            Section("Task") {
                TextField("Title", text: $title, axis: .vertical)
                    .lineLimit(1...3)
                    .accessibilityIdentifier("task-detail-title")
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3...8)
                    .accessibilityIdentifier("task-detail-notes")
            }

            Section("GTD") {
                Picker("Status", selection: $status) {
                    ForEach(GTDStatus.allCases, id: \.self) { status in
                        Text(status.displayName).tag(status)
                    }
                }
                .accessibilityIdentifier("task-detail-status")
                Toggle("Due date", isOn: $hasDueDate)
                if hasDueDate {
                    DatePicker("Due", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                }
            }
        }
        .navigationTitle("Task details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !cleanTitle.isEmpty else { return }
                    task.title = cleanTitle
                    task.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
                    task.status = status
                    task.dueDate = hasDueDate ? dueDate : nil
                    task.updatedAt = .now
                    try? modelContext.save()
                    dismiss()
                }
                .accessibilityIdentifier("task-detail-save")
            }
        }
    }
}

private struct GTDEmptyState: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 32, weight: .medium)).foregroundStyle(Color.themePrimary)
            Text(title).font(.headline)
            Text(message).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
    }
}

private struct GTDCaptureSheet: View {
    private enum Phase: Equatable {
        case capture
        case confirmation
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.title) private var projects: [Project]
    @Query(sort: \Area.name) private var areas: [Area]
    let defaultStatus: GTDStatus
    @State private var selectedStatus: GTDStatus
    @State private var title = ""
    @State private var notes = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date.now
    @State private var tags = ""
    @State private var selectedProjectID: UUID?
    @State private var selectedAreaID: UUID?
    @State private var isSaving = false
    @State private var phase: Phase = .capture
    @State private var persistedItem: TaskItem?
    @State private var didConfirm = false
    @State private var saveErrorMessage: String?

    init(defaultStatus: GTDStatus) {
        self.defaultStatus = defaultStatus
        _selectedStatus = State(initialValue: defaultStatus)
        let processInfo = ProcessInfo.processInfo
        let testTitle = processInfo.arguments.contains("-ui-testing")
            ? (processInfo.environment["SYNAPSE_UI_TEST_CAPTURE_TITLE"] ?? "")
            : ""
        _title = State(initialValue: testTitle)
    }

    var body: some View {
        NavigationStack {
            Group {
                if phase == .capture {
                    captureForm
                } else {
                    confirmationForm
                }
            }
            .navigationTitle(phase == .capture ? "New capture" : "Confirm capture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if phase == .confirmation {
                            leaveAsInbox()
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button { Task { await saveCapture() } } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text(phase == .capture ? "Save" : "Confirm")
                        }
                    }
                    .disabled(
                        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            || isSaving
                            || (phase == .confirmation && persistedItem == nil)
                    )
                }
            }
            .onDisappear {
                // A swipe-back or dismissal from the recommendation screen is
                // still a successful capture, but must leave it raw in Inbox.
                if phase == .confirmation, !didConfirm {
                    resetPersistedItemToInbox()
                }
            }
            .alert("Capture not saved", isPresented: saveErrorPresented) {
                Button("Retry") { Task { await saveCapture() } }
                Button("Keep text", role: .cancel) { saveErrorMessage = nil }
            } message: {
                Text(saveErrorMessage ?? "Your capture is still on screen. Try saving again when storage is available.")
            }
        }
    }

    private var captureForm: some View {
        Form {
            Section("Capture") {
                TextField("What’s on your mind?", text: $title)
                    .accessibilityIdentifier("capture-title-field")
                TextField("Notes (optional)", text: $notes, axis: .vertical)
                    .lineLimit(3...8)
                    .accessibilityIdentifier("capture-notes-field")
            }
            Section {
                Text("It will be sorted with a quick confirmation before it leaves Inbox.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var confirmationForm: some View {
        Form {
            Section {
                TextField("Title", text: $title)
                    .accessibilityIdentifier("capture-confirmation-title")
                TextField("Notes (optional)", text: $notes, axis: .vertical)
                    .lineLimit(3...8)
            } header: {
                Label("Review suggestion", systemImage: "sparkles")
            } footer: {
                Text("Nothing is filed until you confirm. You can change any field.")
            }

            Section("Category") {
                ForEach([GTDStatus.inbox, .nextAction, .waitingFor, .somedayMaybe], id: \.self) { status in
                    Button {
                        selectedStatus = status
                    } label: {
                        HStack {
                            Image(systemName: selectedStatus == status ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedStatus == status ? Color.themePrimary : .secondary)
                            Text(status.displayName)
                            Spacer()
                        }
                    }
                    .foregroundStyle(.primary)
                    .accessibilityIdentifier("capture-category-\(status.rawValue)")
                }
            }

            Section("Area") {
                Button {
                    selectedAreaID = nil
                } label: {
                    triageChoice(title: "No area", isSelected: selectedAreaID == nil)
                }
                .foregroundStyle(.primary)
                ForEach(areas) { area in
                    Button {
                        selectedAreaID = area.id
                    } label: {
                        triageChoice(title: area.name, isSelected: selectedAreaID == area.id)
                    }
                    .foregroundStyle(.primary)
                    .accessibilityIdentifier("capture-area-\(area.id.uuidString)")
                }
            }

            Section("Project") {
                Picker("Project", selection: $selectedProjectID) {
                    Text("No project").tag(UUID?.none)
                    ForEach(projects) { project in Text(project.title).tag(Optional(project.id)) }
                }
            }

            Section("Due date") {
                Toggle("Add due date", isOn: $hasDueDate)
                if hasDueDate {
                    DatePicker("Due", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                }
            }

            Section("Tags") {
                TextField("Context tags (comma separated)", text: $tags)
            }
        }
    }

    private func saveCapture() async {
        isSaving = true
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { isSaving = false; return }

        if phase == .capture {
            let captureText = notes.isEmpty ? cleanTitle : "\(cleanTitle)\n\(notes)"
            // Persist the exact raw capture first. Recommendations are kept in
            // view state until the user confirms them.
            let item = TaskItem(title: cleanTitle, notes: notes, status: .inbox)
            do {
                try CapturePersistenceService.save(item, in: modelContext)
                persistedItem = item

                // processCapture always returns a result, using heuristics when
                // Apple Intelligence is unavailable or fails.
                let recommendation = await CaptureService.shared.processCapture(text: captureText)
                selectedStatus = recommendation.status
                selectedAreaID = areas.first { area in
                    recommendation.contextTags.contains { tag in
                        tag.replacingOccurrences(of: "area:", with: "")
                            .localizedCaseInsensitiveCompare(area.name) == .orderedSame
                    }
                }?.id
                selectedProjectID = GTDInboxBehavior.suggestedProject(in: projects, matching: captureText)?.id
                hasDueDate = recommendation.dueDate != nil
                dueDate = recommendation.dueDate ?? .now
                tags = recommendation.contextTags.map { $0.replacingOccurrences(of: "area:", with: "") }.joined(separator: ", ")
                phase = .confirmation
            } catch {
                // The raw item is already safely in Inbox if classification or
                // the UI transition cannot complete.
            }
        } else {
            applyConfirmationToPersistedItem()
            do {
                try modelContext.save()
                didConfirm = true
                dismiss()
            } catch {
                saveErrorMessage = "Your capture is still on screen. Try saving again when storage is available."
            }
        }
        isSaving = false
    }

    private func applyConfirmationToPersistedItem() {
        guard let item = persistedItem else { return }
        item.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        item.notes = notes
        item.status = selectedStatus
        item.project = projects.first { $0.id == selectedProjectID }
        item.areas = areas.first { $0.id == selectedAreaID }.map { [$0] } ?? []
        let manualTags = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        item.contextTags = manualTags.isEmpty ? [] : Array(Set(manualTags)).sorted()
        item.dueDate = hasDueDate ? dueDate : nil
    }

    private func leaveAsInbox() {
        resetPersistedItemToInbox()
        dismiss()
    }

    private func resetPersistedItemToInbox() {
        guard let item = persistedItem else { return }
        item.status = .inbox
        item.contextTags = []
        item.project = nil
        item.areas = []
        item.dueDate = nil
        try? modelContext.save()
    }

    private func triageChoice(title: String, isSelected: Bool) -> some View {
        HStack {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? Color.themePrimary : .secondary)
            Text(title)
            Spacer()
        }
    }

    private var saveErrorPresented: Binding<Bool> {
        Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )
    }

}

private struct GTDNewAreaSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Area name", text: $name)
                TextField("What does this area represent?", text: $notes, axis: .vertical).lineLimit(2...4)
            }
            .navigationTitle("New area")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        modelContext.insert(Area(name: name, notes: notes))
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct GTDNewProjectSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var title = ""
    @State private var outcome = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Project name", text: $title)
                TextField("Desired outcome", text: $outcome, axis: .vertical).lineLimit(2...4)
            }
            .navigationTitle("New project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        modelContext.insert(Project(title: title, desiredOutcome: outcome))
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
#endif
