struct SessionRecordDto: Codable {
        let id: UUID
        let userId: UUID?
        let startedAt: Date
        let durationSeconds: Int
        let kind: String
        let taskId: UUID?
        
        init(id: UUID, startedAt: Date, duration: TimeInterval, kind: String, taskId: UUID? = nil) {
            self.id = id
            self.userId = nil // Will be set by server
            self.startedAt = startedAt
            self.durationSeconds = Int(duration)
            self.kind = kind.uppercased()
            self.taskId = taskId
        }
    }