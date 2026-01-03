#if os(iOS)
import SwiftUI

struct TaskQuickActionsSheet: View {
    let task: UserTask
    @ObservedObject var taskService: TaskService

    var body: some View {
        Text("Task Quick Actions")
            .font(.headline)
    }
}
#endif
