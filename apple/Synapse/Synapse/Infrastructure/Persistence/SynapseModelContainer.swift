import Foundation
import SwiftData

enum SynapseModelContainer {
    static let cloudKitContainerIdentifier = "iCloud.com.sparkage.synapse"
    static let cloudKitIntegrationConfirmation = "DEDICATED_TEST_APPLE_ACCOUNT"
    static let appSetupCompletedKey = "synapse.appSetupCompleted"
    static let pendingDestinationKey = "synapse.pendingDestination"

    static let schema = Schema(versionedSchema: SynapseSchemaV1.self)

    /// A unique local store keeps each UI-test app process isolated from
    /// CloudKit and from the user's production database.
    static let uiTestStoreURL = FileManager.default.temporaryDirectory
        .appending(path: "SynapseUITests-\(UUID().uuidString).sqlite")

    static let shared: ModelContainer = {
        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: SynapseMigrationPlan.self,
                configurations: configuration(isTesting: isTestingProcess)
            )
        } catch {
            fatalError("Unable to create Synapse model container: \(error)")
        }
    }()

    static func configuration(isTesting: Bool) -> ModelConfiguration {
        if isTesting {
            ModelConfiguration(
                "SynapseUITests",
                schema: schema,
                url: uiTestStoreURL,
                cloudKitDatabase: .none
            )
        } else {
            ModelConfiguration(
                "Synapse",
                schema: schema,
                cloudKitDatabase: .private(cloudKitContainerIdentifier)
            )
        }
    }

    static var isTestingProcess: Bool {
        if isCloudKitIntegrationProcess {
            return false
        }

        let processInfo = ProcessInfo.processInfo
        return processInfo.arguments.contains("-ui-testing") ||
            processInfo.environment["SYNAPSE_UI_TESTING"] == "1" ||
            processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    /// XCTest normally receives an isolated local store. The physical-device
    /// CloudKit integration suite can opt into the real private store only
    /// after an explicit acknowledgement that it uses a dedicated test account.
    static var isCloudKitIntegrationProcess: Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["SYNAPSE_CLOUDKIT_INTEGRATION"] == "1" &&
            environment["SYNAPSE_CLOUDKIT_INTEGRATION_CONFIRM"] == cloudKitIntegrationConfirmation
    }

    /// App Intents can run before the app has ever opened. Keep that
    /// recoverable setup failure away from `shared`'s fatalError path.
    static var appSetupCompleted: Bool {
        isTestingProcess || UserDefaults.standard.bool(forKey: appSetupCompletedKey)
    }

    static func makeIntentContainer() throws -> ModelContainer {
        try ModelContainer(for: schema, configurations: configuration(isTesting: isTestingProcess))
    }
}
