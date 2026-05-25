import Foundation
import SwiftData

/// Rich behavior attached to a `TodoItem`.
///
/// - `.map` opens an address in Apple Maps when tapped.
/// - `.list` shows an inline collapsible checklist below the row.
///
/// Persisted on `TodoItem` as primitives (`attachmentType` + `attachmentData`)
/// so SwiftData can store and CloudKit can sync them; the typed accessor lives
/// in the extension below.
enum TaskAttachment: Codable, Equatable {
    case map(label: String, address: String)
    case list(items: [ChecklistItem])

    var symbol: String {
        switch self {
        case .map: "mappin.circle.fill"
        case .list: "checklist"
        }
    }

    var kindLabel: String {
        switch self {
        case .map: "Map"
        case .list: "List"
        }
    }
}

/// A single line in a `.list` attachment.
struct ChecklistItem: Codable, Equatable, Identifiable, Hashable {
    var id: UUID = UUID()
    var text: String
    var done: Bool = false
}

extension TodoItem {
    /// Typed view over the persisted `attachmentType` / `attachmentData` pair.
    ///
    /// Decoding leans on Swift's automatic `Codable` for enums with associated
    /// values (a `{"map": {...}}` / `{"list": {...}}` shape), so it doesn't need
    /// the `attachmentType` discriminator at all — that field is kept around as
    /// a quick filter/index for queries that want "all tasks with a map" without
    /// decoding every payload.
    var attachment: TaskAttachment? {
        get {
            guard let type = attachmentType, let data = attachmentData else { return nil }
            _ = type
            return try? JSONDecoder().decode(TaskAttachment.self, from: data)
        }
        set {
            guard let value = newValue else {
                attachmentType = nil
                attachmentData = nil
                return
            }
            switch value {
            case .map: attachmentType = "map"
            case .list: attachmentType = "list"
            }
            attachmentData = try? JSONEncoder().encode(value)
        }
    }
}
