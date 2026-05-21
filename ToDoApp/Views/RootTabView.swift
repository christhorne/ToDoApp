import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            ForEach(TaskScope.allCases) { scope in
                TaskListView(scope: scope)
                    .tabItem {
                        Label(scope.displayName, systemImage: scope.systemImage)
                    }
            }
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(AppModelContainer.shared)
}
