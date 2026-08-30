import SwiftData

/// Baseline persisted schema for the first SemVer release.
enum SynapseSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            TaskItem.self,
            Project.self,
            Area.self,
            WeeklyReview.self,
            WeeklyReviewItem.self,
            GmailAccountRecord.self,
            GmailImportedMessageRecord.self,
            GmailSyncCheckpointRecord.self
        ]
    }
}

/// Migration plan for future persisted-model changes.
enum SynapseMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SynapseSchemaV1.self]
    }

    static var stages: [MigrationStage] { [] }
}
