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