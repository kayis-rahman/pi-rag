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