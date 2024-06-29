import TMDB_Dimilian_MVVM
import TMDB_Dimilian_clean
import TMDB_AlonsoUpcomingMovies_og
import SwiftUI
@available(iOS 15,*)
public struct TMDBAPITabView: View {
    
    @State private var currentIndex = 0
        private let views: [AnyView] = [
            AnyView(DMSNowPlayingView()),
            AnyView(TMDB_Dimilian_clean.MovieListView(type: .upcoming)),
            AnyView(SignInView())
        ]
    public init() {}
    public var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                views[currentIndex]
                
                Spacer()
            }
            .navigationBarTitle("TMDB API Example", displayMode: .inline)
            .navigationBarItems(trailing: HStack {
                previousButton
                nextButton
            })
        }
    }

    private var previousButton: some View {
        Button(action: previousView) {
            Text("<")
        }
        .disabled(currentIndex == 0)
    }

    private var nextButton: some View {
        Button(action: nextView) {
            Text(">")
        }
        .disabled(currentIndex == views.count - 1)
    }

    private func nextView() {
        if currentIndex < views.count - 1 {
            currentIndex += 1
        }
    }

    private func previousView() {
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }
}


struct ThirdView: View {
    var body: some View {
        Text("Third View")
            .font(.largeTitle)
    }
}
@available(iOS 15,*)
#Preview {
    TMDBAPITabView()
}
