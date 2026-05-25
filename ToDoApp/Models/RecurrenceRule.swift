import Foundation
import SwiftData

enum RecurrenceKind: String, Codable, CaseIterable, Identifiable {
    case daily, weekly, everyN
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily: "Daily"
        case .weekly: "Weekly"
        case .everyN: "Every N days"
        }
    }
}

@Model
final class RecurrenceRule {
    var id: UUID
    var kindRaw: String
    var intervalDays: Int

    init(id: UUID = UUID(), kind: RecurrenceKind, intervalDays: Int) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.intervalDays = intervalDays
    }

    var kind: RecurrenceKind {
        RecurrenceKind(rawValue: kindRaw) ?? .daily
    }

    var displayName: String {
        switch kind {
        case .daily: "Daily"
        case .weekly: "Weekly"
        case .everyN: "Every \(intervalDays) days"
        }
    }

    /// Compute the next occurrence date after a given completion.
    func nextDate(after lastDay: Date) -> Date {
        let interval: Int
        switch kind {
        case .daily: interval = 1
        case .weekly: interval = 7
        case .everyN: interval = max(1, intervalDays)
        }
        return Calendar.current.date(byAdding: .day, value: interval, to: lastDay) ?? lastDay
    }
}
