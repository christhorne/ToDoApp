import SwiftUI

struct RootTabView: View {
    @State private var selection: Int = 0

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tag(0)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            ForEach(Array(TaskScope.allCases.enumerated()), id: \.element) { index, scope in
                PlannerView(scope: scope)
                    .tag(index + 1)
                    .tabItem {
                        Label(scope.displayName, systemImage: scope.systemImage)
                    }
            }
        }
        .tint(tintColor)
    }

    private var tintColor: Color {
        if selection == 0 { return .indigo }
        let scopeIndex = selection - 1
        guard scopeIndex >= 0, scopeIndex < TaskScope.allCases.count else {
            return .accentColor
        }
        return TaskScope.allCases[scopeIndex].color
    }
}

#Preview {
    RootTabView()
        .modelContainer(AppModelContainer.shared)
}
