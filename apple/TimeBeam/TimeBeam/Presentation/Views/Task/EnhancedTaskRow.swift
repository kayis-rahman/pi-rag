#if os(iOS)
import SwiftUI

struct EnhancedTaskRow: View {
    let task: UserTask
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Status indicator
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                // Task details
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if let description = task.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.themeCardBackground)
            )
        }
        .buttonStyle(.plain)
    }

    private var statusColor: Color {
        switch task.status {
        case .todo: return .orange
        case .inProgress: return .blue
        case .completed: return .green
        }
    }
}
#endif
