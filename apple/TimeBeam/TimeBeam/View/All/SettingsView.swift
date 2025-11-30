import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var timer: PomodoroTimer
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                durationPickerLink(for: .work)
                durationPickerLink(for: .break)
                durationPickerLink(for: .longBreak)

                Section {
                    Toggle("Auto-start next session", isOn: Binding(
                        get: { timer.autoStartNextSession },
                        set: { timer.autoStartNextSession = $0 }
                    ))
                }

                Section {
                    Button("Reset durations to defaults") {
                        timer.resetDurationsToDefaults()
                    }
                }
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func durationPickerLink(for phase: Phase) -> some View {
        let (title, duration) = {
            switch phase {
            case .work: return ("Focus", timer.workDuration)
            case .break: return ("Short Break", timer.breakDuration)
            case .longBreak: return ("Long Break", timer.longBreakDuration)
            }
        }()

        return NavigationLink {
            MinutesPickerView(
                title: title,
                initialMinutes: duration / 60
            ) { minutes in
                timer.updateDurations(
                    workMinutes: phase == .work ? minutes : timer.workDuration / 60,
                    shortBreakMinutes: phase == .break ? minutes : timer.breakDuration / 60,
                    longBreakMinutes: phase == .longBreak ? minutes : timer.longBreakDuration / 60
                )
            }
        } label: {
            HStack {
                Text(title)
                Spacer()
                Text("\(duration / 60)m")
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct MinutesPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let onSelect: (Int) -> Void
    @State private var selectedMinutes: Int
    private let minutesRange = Array(stride(from: 5, through: 120, by: 5))

    init(title: String, initialMinutes: Int, onSelect: @escaping (Int) -> Void) {
        self.title = title
        self.onSelect = onSelect
        let closest = minutesRange.min(by: { abs($0 - initialMinutes) < abs($1 - initialMinutes) }) ?? initialMinutes
        self._selectedMinutes = State(initialValue: closest)
    }

    var body: some View {
        VStack {
            Picker("Minutes", selection: $selectedMinutes) {
                ForEach(minutesRange, id: \.self) { Text("\($0) minutes").tag($0) }
            }
            #if os(iOS)
            .pickerStyle(.wheel)
            #endif
            .labelsHidden()
            
            Button("Done") {
                onSelect(selectedMinutes)
                dismiss()
            }
        }
        .navigationTitle(title)
    }
}
