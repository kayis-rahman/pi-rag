#if os(iOS)
import SwiftUI

struct TaskCardView: View {
    let task: UserTask
    let style: TaskCardStyle
    let selectionAction: () -> Void
    let completionAction: () -> Void

    @State private var isCompleted = false
    @State private var showUndoButton = false

    var body: some View {
        Button(action: selectionAction) {
            VStack(spacing: 8) {
                // Header with checkbox and title
                HStack(spacing: 8) {
                    Image(systemName: task.status == .completed ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(task.status == .completed ? .themePrimary : .secondary)

                    Text(task.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    if task.status == .completed {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.themePrimary)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.themeCardBackground)
            )
        }
        .buttonStyle(.plain)
    }
}
#endif
