import SwiftUI
import SwiftData

@main
struct ToDoAppApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(AppModelContainer.shared)
    }
}
