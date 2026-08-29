#if os(iOS)
import SwiftUI

struct TaskQuickActionsSheet: View {
    let task: UserTask
    @Environment(TaskService.self) var taskService

    var body: some View {
        Text("Task Quick Actions")
            .font(.headline)
    }
}
#endif
