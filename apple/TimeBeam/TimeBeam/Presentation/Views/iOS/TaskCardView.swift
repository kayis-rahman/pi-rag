import SwiftUI
import PomodoroTimer

// Extracted from iOSContentView.swift

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

                    Button {

                        withAnimation(.spring()) {

                            isCompleted.toggle()

                            if isCompleted {

                                completionAction()

                                showUndoButton = true

                                // Auto-hide undo button after 3 seconds

                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {

                                    withAnimation {

                                        showUndoButton = false

                                    }

                                }

                            }

                        }

                    } label: {

                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")

                            .foregroundColor(isCompleted ? .green : .secondary)

                            .font(.system(size: 16))

                    }



                    Text(task.title)

                        .font(.subheadline)

                        .fontWeight(.medium)

                        .foregroundColor(.primary)

                        .lineLimit(1)



                    Spacer()

                }



                if let description = task.description, !description.isEmpty {

                    Text(description)

                        .font(.caption)

                        .foregroundColor(.secondary)

                        .lineLimit(2)

                        .frame(maxWidth: .infinity, alignment: .leading)

                }



                // Undo button

                if showUndoButton {

                    Button("Undo") {

                        withAnimation {

                            isCompleted = false

                            showUndoButton = false

                            undoCompletion()

                        }

                    }

                    .font(.caption)

                    .foregroundColor(.themePrimary)

                    .padding(.horizontal, 8)

                    .padding(.vertical, 4)

                    .background(Color.themeCardBackground.opacity(0.8))

                    .clipShape(Capsule())

                    .frame(maxWidth: .infinity, alignment: .leading)

                }

            }

            .padding(12)

            .frame(width: 160, height: style.height)

            .background(style.background)

            .clipShape(style.shape)

            .overlay(

                style.border

            )

            .shadow(color: style.shadowColor, radius: style.shadowRadius, x: 0, y: 2)

        }

        .buttonStyle(.plain)

        .gesture(

            DragGesture(minimumDistance: 50)

                .onEnded { value in

                    if value.translation.width < -50 {

                        // Right swipe to complete

                        withAnimation(.spring()) {

                            isCompleted = true

                            completionAction()

                            showUndoButton = true

                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {

                                withAnimation {

                                    showUndoButton = false

                                }

                            }

                        }

                    }

                }

        )

    }



    private func undoCompletion() {

        // This would call TaskService.undoTaskCompletion

        // For now, just reset the local state

        print("Undo completion for task: \(task.title)")

    }

}



enum TaskCardStyle {

    case classic, modern, minimal, colorful



    var height: CGFloat {

        switch self {

        case .classic: return 100

        case .modern: return 120

        case .minimal: return 80

        case .colorful: return 110

        }

    }



    var background: some View {

        Group {

            switch self {

            case .classic:

                RoundedRectangle(cornerRadius: 12)

                    .fill(Color.themeCardBackground.opacity(0.9))

            case .modern:

                RoundedRectangle(cornerRadius: 16)

                    .fill(Color.themeCardBackground.opacity(0.95))

                    .overlay(

                        RoundedRectangle(cornerRadius: 16)

                            .stroke(Color.themePrimary.opacity(0.3), lineWidth: 1)

                    )

            case .minimal:

                RoundedRectangle(cornerRadius: 8)

                    .fill(Color.themeCardBackground.opacity(0.7))

            case .colorful:

                RoundedRectangle(cornerRadius: 20)

                    .fill(

                        LinearGradient(

                            colors: [Color.themePrimary.opacity(0.2), Color.themeSecondary.opacity(0.3)],

                            startPoint: .topLeading,

                            endPoint: .bottomTrailing

                        )

                    )

            }

        }

    }



    var shape: some Shape {

        switch self {

        case .classic: return RoundedRectangle(cornerRadius: 12)

        case .modern: return RoundedRectangle(cornerRadius: 16)

        case .minimal: return RoundedRectangle(cornerRadius: 8)

        case .colorful: return RoundedRectangle(cornerRadius: 20)

        }

    }



    var border: some View {

        Group {

            switch self {

            case .classic, .minimal:

                EmptyView()

            case .modern:

                RoundedRectangle(cornerRadius: 16)

                    .stroke(Color.themePrimary.opacity(0.3), lineWidth: 1)

            case .colorful:

                RoundedRectangle(cornerRadius: 20)

                    .stroke(Color.themePrimary.opacity(0.5), lineWidth: 1)

            }

        }

    }



    var shadowColor: Color {

        switch self {

        case .classic: return Color.black.opacity(0.1)

        case .modern: return Color.themePrimary.opacity(0.2)

        case .minimal: return Color.black.opacity(0.05)

        case .colorful: return Color.themePrimary.opacity(0.3)

        }

    }



    var shadowRadius: CGFloat {

        switch self {

        case .classic: return 4

        case .modern: return 6

        case .minimal: return 2

        case .colorful: return 8

        }

    }

}



private struct CycleProgressView: View {
