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
        let config: ModelConfiguration = useCloudKit
            ? ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .automatic)
            : ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
}
