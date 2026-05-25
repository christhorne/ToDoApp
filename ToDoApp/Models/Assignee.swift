import SwiftUI

/// A demo "user" the planner can assign tasks to. Real accounts come later —
/// for now Alex and Sam are the two fake people we render chips for.
struct Assignee: Identifiable, Hashable {
    let id: String
    let displayName: String
    let initial: String
    let color: Color

    static let alex = Assignee(id: "alex", displayName: "Alex", initial: "A", color: .blue)
    static let sam = Assignee(id: "sam", displayName: "Sam", initial: "S", color: .purple)
    static let all: [Assignee] = [alex, sam]

    static func find(id: String?) -> Assignee? {
        guard let id else { return nil }
        return all.first { $0.id == id }
    }
}
