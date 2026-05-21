import Foundation

enum TaskScope: String, Codable, CaseIterable, Identifiable {
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
}
