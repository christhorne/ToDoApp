import Foundation
import SwiftData

enum WidgetStore {
    private static let modelContainer: ModelContainer? = {
        let schema = Schema([TodoItem.self])
        let config: ModelConfiguration
        if let url = SharedAppGroup.storeURL {
            config = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        } else {
            return nil
        }
        return try? ModelContainer(for: schema, configurations: [config])
    }()

    static func fetchOpenToday(limit: Int) -> [WidgetTodo] {
        guard let container = modelContainer else { return [] }
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<TodoItem>(
            sortBy: [SortDescriptor(\TodoItem.sortOrder), SortDescriptor(\TodoItem.createdAt)]
        )
        descriptor.fetchLimit = 50
        let items = (try? context.fetch(descriptor)) ?? []
        return items
            .filter { $0.scope == .daily && $0.completedAt == nil }
            .prefix(limit)
            .map { WidgetTodo(id: UUID(), title: $0.title) }
    }
}
