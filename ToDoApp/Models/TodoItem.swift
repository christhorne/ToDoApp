import Foundation
import SwiftData

@Model
final class TodoItem {
    var title: String
    var day: Date = Date.now
    var createdAt: Date
    var completedAt: Date?
    var sortOrder: Int
    var assigneeId: String?

    init(
        title: String,
        day: Date = .now,
        createdAt: Date = .now,
        completedAt: Date? = nil,
        sortOrder: Int = 0,
        assigneeId: String? = nil
    ) {
        self.title = title
        self.day = Calendar.current.startOfDay(for: day)
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.sortOrder = sortOrder
        self.assigneeId = assigneeId
    }

    var isComplete: Bool { completedAt != nil }
}
