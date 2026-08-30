import XCTest

@testable import Synapse

final class SynapseModelContainerTests: XCTestCase {
    func testProductionConfigurationUsesThePrivateSynapseCloudKitContainer() {
        let configuration = SynapseModelContainer.configuration(isTesting: false)

        XCTAssertFalse(configuration.isStoredInMemoryOnly)
        XCTAssertEqual(configuration.cloudKitContainerIdentifier, "iCloud.com.sparkage.synapse")
    }

    func testTestingConfigurationUsesAnIsolatedLocalStoreWithoutCloudKit() {
        let configuration = SynapseModelContainer.configuration(isTesting: true)

        XCTAssertFalse(configuration.isStoredInMemoryOnly)
        XCTAssertTrue(configuration.url.lastPathComponent.hasPrefix("SynapseUITests-"))
        XCTAssertNil(configuration.cloudKitContainerIdentifier)
    }
}
