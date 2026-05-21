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

    /// Open tasks due today or earlier — mirrors the Today tab.
    static func fetchOpenToday(limit: Int) -> [WidgetTodo] {
        guard let container = modelContainer else { return [] }
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<TodoItem>(
            sortBy: [SortDescriptor(\TodoItem.day), SortDescriptor(\TodoItem.sortOrder)]
        )
        descriptor.fetchLimit = 100
        let items = (try? context.fetch(descriptor)) ?? []
        let today = CalendarHelper.today
        return items
            .filter { $0.completedAt == nil && $0.day <= today }
            .prefix(limit)
            .map { WidgetTodo(id: UUID(), title: $0.title) }
    }
}
