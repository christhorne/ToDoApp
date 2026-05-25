import Foundation

/// Persists a free-text "Week's Focus" string per calendar week using UserDefaults.
/// Keyed by the ISO date string of Monday of that week.
enum WeekFocus {
    private static let keyPrefix = "weekFocus_"

    private static func storageKey(for weekStart: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return keyPrefix + formatter.string(from: weekStart)
    }

    static func get(for weekStart: Date) -> String {
        UserDefaults.standard.string(forKey: storageKey(for: weekStart)) ?? ""
    }

    static func set(_ value: String, for weekStart: Date) {
        UserDefaults.standard.set(value, forKey: storageKey(for: weekStart))
    }

    /// Convenience: get/set for the current week.
    static var currentWeekStart: Date {
        CalendarHelper.daysOfCurrentWeek().first ?? CalendarHelper.today
    }

    static var current: String {
        get { get(for: currentWeekStart) }
        set { set(newValue, for: currentWeekStart) }
    }
}
