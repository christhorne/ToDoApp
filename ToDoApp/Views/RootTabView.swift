import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            TaskListView(scope: .daily)
                .tabItem {
                    Label(TaskScope.daily.displayName, systemImage: TaskScope.daily.systemImage)
                }

            Text("Week")
                .tabItem {
                    Label(TaskScope.weekly.displayName, systemImage: TaskScope.weekly.systemImage)
                }

            Text("Weekend")
                .tabItem {
                    Label(TaskScope.weekend.displayName, systemImage: TaskScope.weekend.systemImage)
                }
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(AppModelContainer.shared)
}
