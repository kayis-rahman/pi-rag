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