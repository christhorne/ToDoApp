import Foundation
import SwiftData

@Model
final class TodoItem {
    var title: String
    var notes: String?
    var scope: TaskScope
    var dueDate: Date?
    var createdAt: Date
    var completedAt: Date?
    var sortOrder: Int

    init(
        title: String,
        notes: String? = nil,
        scope: TaskScope = .daily,
        dueDate: Date? = nil,
        createdAt: Date = .now,
        completedAt: Date? = nil,
        sortOrder: Int = 0
    ) {
        self.title = title
        self.notes = notes
        self.scope = scope
        self.dueDate = dueDate
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.sortOrder = sortOrder
    }

    var isComplete: Bool { completedAt != nil }
}
