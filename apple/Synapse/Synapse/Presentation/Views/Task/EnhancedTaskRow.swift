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
                    .glassEffectInteractiveConditional(in: .capsule)

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
                    .fill(Color(red: 255/255, green: 255/255, blue: 255, opacity: 0.6))
            )
        }
        .buttonStyle(.plain)
        .glassEffectCardConditional(cornerRadius: 12)
    }

    private var statusColor: Color {
        switch task.status {
        case .todo: return .themeOrangeAccent
        case .inProgress: return .blue
        case .completed: return .themeSuccess
        }
    }
}
#endif
