import SwiftUI

struct RootTabView: View {
    @State private var selection: TaskScope = .daily

    var body: some View {
        TabView(selection: $selection) {
            ForEach(TaskScope.allCases) { scope in
                TaskListView(scope: scope)
                    .tag(scope)
                    .tabItem {
                        Label(scope.displayName, systemImage: scope.systemImage)
                    }
            }
        }
        .tint(selection.color)
    }
}

#Preview {
    RootTabView()
        .modelContainer(AppModelContainer.shared)
}
