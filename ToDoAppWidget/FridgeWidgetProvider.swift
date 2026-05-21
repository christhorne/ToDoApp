import Foundation
import WidgetKit

struct FridgeWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> FridgeWidgetEntry {
        FridgeWidgetEntry(date: .now, items: [
            WidgetTodo(id: UUID(), title: "Plan dinner"),
            WidgetTodo(id: UUID(), title: "Pick up dry cleaning"),
            WidgetTodo(id: UUID(), title: "Email Sabrina"),
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (FridgeWidgetEntry) -> Void) {
        let items = WidgetStore.fetchOpenToday(limit: 5)
        completion(FridgeWidgetEntry(date: .now, items: items))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FridgeWidgetEntry>) -> Void) {
        let items = WidgetStore.fetchOpenToday(limit: 5)
        let entry = FridgeWidgetEntry(date: .now, items: items)
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}
