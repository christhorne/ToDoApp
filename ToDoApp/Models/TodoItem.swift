import Foundation
import SwiftData

@Model
final class TodoItem {
    var title: String
    var day: Date = Date.now
    var createdAt: Date
    var completedAt: Date?
    var sortOrder: Int

    // Assignee — set by Agent B's Assignee feature. Stores an Assignee.id string
    // (e.g. "alex", "sam"). Nil means unassigned.
    var assigneeId: String?

    // Optional time-of-day for a task (e.g. "3:00 PM · Pick up Arthur"). Only
    // the hour/minute components are meaningful; the date portion is ignored.
    var time: Date?

    // Emoji reactions left on a completed task ("🙏", "❤️", ...). Display only —
    // no per-user attribution for now.
    var reactions: [String] = []

    // Link to a RecurrenceRule; if set, this task is a recurring template or
    // generated instance. recurrenceParentId points to the template that
    // produced an instance.
    var recurrenceRuleId: UUID?
    var recurrenceParentId: UUID?

    // Attachment payload — Agent F's task-types feature. attachmentType is
    // "map" or "list"; attachmentData is JSON-encoded payload specific to the
    // type. Modeled as primitives for SwiftData compatibility.
    var attachmentType: String?
    var attachmentData: Data?

    init(
        title: String,
        day: Date = .now,
        createdAt: Date = .now,
        completedAt: Date? = nil,
        sortOrder: Int = 0,
        assigneeId: String? = nil,
        time: Date? = nil,
        reactions: [String] = [],
        recurrenceRuleId: UUID? = nil,
        recurrenceParentId: UUID? = nil,
        attachmentType: String? = nil,
        attachmentData: Data? = nil
    ) {
        self.title = title
        self.day = Calendar.current.startOfDay(for: day)
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.sortOrder = sortOrder
        self.assigneeId = assigneeId
        self.time = time
        self.reactions = reactions
        self.recurrenceRuleId = recurrenceRuleId
        self.recurrenceParentId = recurrenceParentId
        self.attachmentType = attachmentType
        self.attachmentData = attachmentData
    }

    var isComplete: Bool { completedAt != nil }
}
