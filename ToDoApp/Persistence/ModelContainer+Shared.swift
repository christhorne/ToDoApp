import Foundation
import SwiftData

enum AppModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([TodoItem.self, RecurrenceRule.self])
        let config = makeConfiguration(schema: schema)
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            DemoSeeder.seedIfNeeded(container: container)
            return container
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    private static func makeConfiguration(schema: Schema) -> ModelConfiguration {
        let cloudKit: ModelConfiguration.CloudKitDatabase = AppConfig.useCloudKit ? .automatic : .none
        if let url = SharedAppGroup.storeURL {
            return ModelConfiguration(schema: schema, url: url, cloudKitDatabase: cloudKit)
        }
        return ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: cloudKit)
    }
}
