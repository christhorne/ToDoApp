import Foundation
import SwiftData

enum AppModelContainer {
    // Flip to `true` after wiring iCloud + CloudKit capability and a real
    // development team in Xcode → Target → Signing & Capabilities. With
    // the capability in place, SwiftData syncs the private database across
    // the signed-in iCloud account's devices automatically. See README.md.
    private static let useCloudKit = false

    static let shared: ModelContainer = {
        let schema = Schema([TodoItem.self])
        let config = makeConfiguration(schema: schema)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    private static func makeConfiguration(schema: Schema) -> ModelConfiguration {
        let cloudKit: ModelConfiguration.CloudKitDatabase = useCloudKit ? .automatic : .none
        if let url = SharedAppGroup.storeURL {
            return ModelConfiguration(schema: schema, url: url, cloudKitDatabase: cloudKit)
        }
        return ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: cloudKit)
    }
}
