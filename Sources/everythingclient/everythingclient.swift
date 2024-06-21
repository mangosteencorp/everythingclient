import SwiftUI

public struct RootContentView: View {
    @State private var selectedTab = 0
    public init() {}
    public var body: some View {
        TabView(selection: $selectedTab){
            TMDBAPITabView()
                .tabItem {
                    Label(
                        title: { Text("TMDB") },
                        icon: { Image(systemName: "movieclapper") }
                    )
                }
            Text("GitHub API")
                .tabItem { Label("GitHub API", systemImage: "desktopcomputer") }
        }
    }
}

#Preview {
    RootContentView()
}
