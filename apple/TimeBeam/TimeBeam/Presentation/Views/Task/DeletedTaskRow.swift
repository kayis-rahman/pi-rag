#if os(iOS)
import SwiftUI

struct DeletedTaskRow: View {
    let item: RecycleBinItem
    let onRestore: () -> Void
    let onDelete: () -> Void

    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "trash.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.themePrimary.opacity(0.6))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.task.title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Deleted \(relativeDateString(from: item.deletedAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: onRestore) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                }

                Button(action: onDelete) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.themeCardBackground.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.themePrimary.opacity(0.05), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    private func relativeDateString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: date, to: now)

        if let days = components.day, days == 1 {
            return "1 day ago"
        } else if let days = components.day {
            return "\(days) days ago"
        }
        return "recently"
    }
}
#endif
