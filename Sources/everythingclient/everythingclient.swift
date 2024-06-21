import SwiftUI

public struct RootContentView: View {
    @State private var selectedTab = 0
    public init() {}
    public var body: some View {
        TabView(selection: $selectedTab){
            if #available(iOS 15, *) {
                TMDBAPITabView()
                    .tabItem {
                        Label(
                            title: { Text("TMDB") },
                            icon: { Image(systemName: "movieclapper") }
                        )
                    }
            } 
            Text("GitHub API")
                .tabItem { Label("GitHub API", systemImage: "desktopcomputer") }
        }
    }
}

#Preview {
    RootContentView()
}
