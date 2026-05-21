import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            Text("Today")
                .tabItem { Label("Today", systemImage: "sun.max") }

            Text("Week")
                .tabItem { Label("Week", systemImage: "calendar") }

            Text("Weekend")
                .tabItem { Label("Weekend", systemImage: "house") }
        }
    }
}

#Preview {
    RootTabView()
}
