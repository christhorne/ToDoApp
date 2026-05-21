import Foundation

/// Day-granular date math shared by the planner views and the widget.
enum CalendarHelper {
    /// A calendar whose weeks run Monday–Sunday, regardless of device locale.
    static let weekCalendar: Calendar = {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        return calendar
    }()

    static var today: Date {
        weekCalendar.startOfDay(for: .now)
    }

    /// Monday through Sunday of the week containing today.
    static func daysOfCurrentWeek() -> [Date] {
        guard let interval = weekCalendar.dateInterval(of: .weekOfYear, for: .now) else {
            return [today]
        }
        var days: [Date] = []
        var cursor = weekCalendar.startOfDay(for: interval.start)
        for _ in 0..<7 {
            days.append(cursor)
            guard let next = weekCalendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return days
    }

    /// Saturday and Sunday of the current week.
    static func weekendDays() -> [Date] {
        daysOfCurrentWeek().filter {
            let weekday = weekCalendar.component(.weekday, from: $0)
            return weekday == 1 || weekday == 7
        }
    }

    static var tomorrow: Date {
        weekCalendar.date(byAdding: .day, value: 1, to: today) ?? today
    }

    /// The upcoming (or current) Saturday — never a past date.
    static var upcomingSaturday: Date {
        let saturday = weekendDays().first ?? today
        if saturday < today {
            return weekCalendar.date(byAdding: .day, value: 7, to: saturday) ?? saturday
        }
        return saturday
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
    static func longDateWithOrdinal(_ date: Date) -> String {
        let dayNumber = weekCalendar.component(.day, from: date)
        let ordinal = ordinalFormatter.string(from: NSNumber(value: dayNumber)) ?? "\(dayNumber)"
        return "\(weekdayMonthFormatter.string(from: date)) \(ordinal)"
    }
}
