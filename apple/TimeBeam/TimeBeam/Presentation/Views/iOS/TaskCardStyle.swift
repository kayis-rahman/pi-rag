import SwiftUI
import PomodoroTimer

// Extracted from iOSContentView.swift

    let completed: Int

    let total: Int



    var body: some View {

        HStack(spacing: 8) {

            ForEach(0..<total, id: \.self) { index in

                Circle()

                    .fill(index < completed ? Color.themePrimary : Color.themeTextSecondary.opacity(0.3))

                    .frame(width: 10, height: 10)

            }

        }

    }

}



#Preview {

    iOSContentView()

        .environmentObject(PomodoroTimer())

        .environmentObject(SessionLogger())

        .environmentObject(AuthManager())

        .environmentObject(TaskService())

}

#endif
