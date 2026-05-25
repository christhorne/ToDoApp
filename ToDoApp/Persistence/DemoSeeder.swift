import Foundation
import SwiftData

/// Seeds two demo tasks the first time the app runs on a device so the
/// attachment features (`.map`, `.list`) have something to show in a demo
/// without needing manual setup.
enum DemoSeeder {
    private static let didSeedKey = "didSeedAttachmentDemo"

    static func seedIfNeeded(container: ModelContainer) {
        guard !UserDefaults.standard.bool(forKey: didSeedKey) else { return }

        let context = ModelContext(container)

        let pickup = TodoItem(
            title: "Pick up Arthur",
            day: CalendarHelper.tomorrow,
            sortOrder: 0
        )
        pickup.attachment = .map(
            label: "Arthur's School",
            address: "1 Infinite Loop, Cupertino, CA"
        )
        context.insert(pickup)

        let groceries = TodoItem(
            title: "Saturday groceries",
            day: CalendarHelper.upcomingSaturday,
            sortOrder: 0
        )
        groceries.attachment = .list(items: [
            ChecklistItem(text: "Milk"),
            ChecklistItem(text: "Eggs"),
            ChecklistItem(text: "Bread"),
            ChecklistItem(text: "Apples"),
            ChecklistItem(text: "Yogurt")
        ])
        context.insert(groceries)

        do {
            try context.save()
            UserDefaults.standard.set(true, forKey: didSeedKey)
        } catch {
            // Silently skip seeding on failure — the app still works without it.
            // Leaving the flag unset means we'll retry on next launch.
        }
    }
}
