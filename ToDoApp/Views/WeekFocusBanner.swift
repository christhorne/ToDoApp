import SwiftUI

/// "What do you want to focus on this week?" inline editor shown above the
/// day list on the Week and Weekend tabs. Reads and writes a single string
/// keyed by the current ISO week so the Week and Weekend tabs share state.
struct WeekFocusBanner: View {
    let scope: TaskScope

    @AppStorage(WeekFocus.currentWeekKey, store: WeekFocus.defaults)
    private var focusText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(scope.color)
                Text(headerText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
            TextField(placeholderText, text: $focusText, axis: .vertical)
                .font(.body)
                .lineLimit(1...3)
                .textFieldStyle(.plain)
        }
    }

    private var headerText: String {
        scope == .weekend ? "Weekend's Focus" : "Week's Focus"
    }

    private var placeholderText: String {
        scope == .weekend
            ? "What do you want to focus on this weekend?"
            : "What do you want to focus on this week?"
    }
}
