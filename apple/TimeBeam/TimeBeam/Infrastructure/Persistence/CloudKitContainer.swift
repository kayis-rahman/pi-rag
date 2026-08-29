import SwiftData

enum CloudKitContainerConfiguration {
    static let identifier = "iCloud.com.sparkage.time-beam"
}

/// The shared local store for task data and the managed CloudKit replica.
enum PersistenceController {
    static let shared: ModelContainer = {
        let schema = Schema([
            GTDTask.self,
            Project.self,
            Area.self,
            WeeklyReview.self,
            WeeklyReviewItem.self
        ])

        let configuration = ModelConfiguration(
            "Synapse",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .automatic,
            cloudKitDatabase: .private(CloudKitContainerConfiguration.identifier)
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to create the Synapse model container: \(error)")
        }
    }()
}
