import Foundation

/// Per-week (or weekend) "what do you want to focus on?" prompt.
///
/// The text is persisted in `UserDefaults` (the shared App Group store when
/// available, falling back to `.standard`) under a key that rotates each
/// ISO week. Week and Weekend tabs get separate keys so they don't overwrite
/// each other.
enum WeekFocus {
    /// `UserDefaults` instance used for reads and writes. Uses the shared App
    /// Group store if it exists (so the widget can read the same value later);
    /// otherwise falls back to `.standard` for development & previews.
    static var defaults: UserDefaults {
        UserDefaults(suiteName: SharedAppGroup.identifier) ?? .standard
    }

    /// Storage key for the week containing `date`. Key format depends on the
    /// scope — Week tab uses `weekFocus.2026-W21` (preserves the original key
    /// format), Weekend tab uses `weekendFocus.2026-W21`.
    static func storageKey(for date: Date, scope: TaskScope) -> String {
        let calendar = CalendarHelper.weekCalendar
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let year = components.yearForWeekOfYear ?? 0
        let week = components.weekOfYear ?? 0
        let weekId = "\(year)-W\(String(format: "%02d", week))"
        switch scope {
        case .weekend: return "weekendFocus.\(weekId)"
        default: return "weekFocus.\(weekId)"
        }
    }

    /// Storage key for the current week within the given scope.
    static func currentKey(scope: TaskScope) -> String {
        storageKey(for: .now, scope: scope)
    }
}
