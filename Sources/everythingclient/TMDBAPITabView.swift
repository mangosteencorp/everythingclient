import SwiftUI

@available(iOS 15, *)
struct TMDBAPITabView: View {
    // @State private var selectionTab: Int = 0
    let nowplayingView: DMSNowPlayingView = DMSNowPlayingView()
    var body: some View {
        TabView  {
            NowPlayingViewControllerRepresentable()
            nowplayingView.tag(1)
            Text("Tab Content 2").tag(2)
        }
        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
}

#Preview {
    TMDBAPITabView()
}
