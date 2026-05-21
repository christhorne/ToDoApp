import Foundation
import WidgetKit

struct FridgeWidgetEntry: TimelineEntry {
    let date: Date
    let items: [WidgetTodo]
}

struct WidgetTodo: Identifiable, Hashable {
    let id: UUID
    let title: String
}
