import Foundation

/// Per-week "what do you want to focus on this week?" prompt.
///
/// The text is persisted in `UserDefaults` (the shared App Group store when
/// available, falling back to `.standard`) under a key that rotates each
/// ISO week, so a Monday rolls the planner into a fresh focus while still
/// keeping prior weeks' text around if the user revisits them.
enum WeekFocus {
    private static let keyPrefix = "weekFocus."

    /// `UserDefaults` instance used for reads and writes. Uses the shared App
    /// Group store if it exists (so the widget can read the same value later);
    /// otherwise falls back to `.standard` for development & previews.
    static var defaults: UserDefaults {
        UserDefaults(suiteName: SharedAppGroup.identifier) ?? .standard
    }

    /// Storage key for the week containing `date`. The key embeds the ISO
    /// year and week number, e.g. `weekFocus.2026-W21`, so the focus rotates
    /// automatically when the week changes.
    static func storageKey(for date: Date) -> String {
        let calendar = CalendarHelper.weekCalendar
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let year = components.yearForWeekOfYear ?? 0
        let week = components.weekOfYear ?? 0
        return "\(keyPrefix)\(year)-W\(String(format: "%02d", week))"
    }

    /// Convenience storage key for the week containing today.
    static var currentWeekKey: String {
        storageKey(for: .now)
    }
}
