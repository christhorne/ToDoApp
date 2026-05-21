import Foundation

/// Day-granular date math shared by the planner views and the widget.
enum CalendarHelper {
    static var today: Date {
        Calendar.current.startOfDay(for: .now)
    }

    /// The seven days of the week containing today, respecting the user's
    /// first-weekday setting.
    static func daysOfCurrentWeek(calendar: Calendar = .current) -> [Date] {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: .now) else {
            return [today]
        }
        var days: [Date] = []
        var cursor = calendar.startOfDay(for: interval.start)
        for _ in 0..<7 {
            days.append(cursor)
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return days
    }

    /// Saturday and Sunday of the current week.
    static func weekendDays(calendar: Calendar = .current) -> [Date] {
        daysOfCurrentWeek(calendar: calendar).filter {
            let weekday = calendar.component(.weekday, from: $0)
            return weekday == 1 || weekday == 7
        }
    }

    private static let ordinalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .ordinal
        return f
    }()

    private static let weekdayMonthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM"
        return f
    }()

    /// A full date with an ordinal day, e.g. "Thursday, May 21st".
    static func longDateWithOrdinal(_ date: Date, calendar: Calendar = .current) -> String {
        let dayNumber = calendar.component(.day, from: date)
        let ordinal = ordinalFormatter.string(from: NSNumber(value: dayNumber)) ?? "\(dayNumber)"
        return "\(weekdayMonthFormatter.string(from: date)) \(ordinal)"
    }
}
