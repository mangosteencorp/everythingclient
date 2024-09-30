import TMDB_Dimilian_MVVM
import TMDB_Dimilian_clean

import TMDB_dancarvajc_Login
import SwiftUI
@available(iOS 15,*)
public struct TMDBAPITabView: View {
    
    @State private var currentIndex = 0
    private let views: [AnyView]
    public init(tmdbKey: String) {
        views =  [
            AnyView(DMSNowPlayingView(apiKey: tmdbKey)),
            AnyView(TMDB_Dimilian_clean.MovieListPage(apiKey: tmdbKey, type: .upcoming)),
            
            AnyView(ProfileTabView()) // {{ edit_1 }} Added LoginView
        ]
    }
    public var body: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
                    TabView {
                        ForEach(0..<views.count, id: \.self) { index in
                            views[index]
                                .tabItem {
                                    Label(tabTitle(for: index), systemImage: tabIcon(for: index))
                                }
                        }
                    }.tabViewStyle(PageTabViewStyle())
        } else {
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
            }.navigationViewStyle(StackNavigationViewStyle())
        }
    }
    
    private func tabTitle(for index: Int) -> String {
            switch index {
            case 0: return "Now Playing"
            case 1: return "Upcoming"
            case 2: return "Profile"
            default: return ""
            }
        }
        
        private func tabIcon(for index: Int) -> String {
            switch index {
            case 0: return "play.circle"
            case 1: return "calendar"
            case 2: return "person"
            default: return ""
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

@available(iOS 15,*)
#Preview {
    TMDBAPITabView(tmdbKey: "")
}
