import SwiftUI

/// Identifies one of the three planner tabs. Not stored on tasks — tasks
/// carry a `day`, and each scope is a window onto those dated tasks.
enum TaskScope: String, CaseIterable, Identifiable {
    case daily
    case weekly
    case weekend

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily: "Today"
        case .weekly: "Week"
        case .weekend: "Weekend"
        }
    }

    var systemImage: String {
        switch self {
        case .daily: "sun.max"
        case .weekly: "calendar"
        case .weekend: "house"
        }
    }

    /// Accent color for this tab — Today is warm, Week is calm, Weekend is fresh.
    var color: Color {
        switch self {
        case .daily: .orange
        case .weekly: .blue
        case .weekend: .green
        }
    }
}
