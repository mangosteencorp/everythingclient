import TMDB_MVVM_MLS
import TMDB_clean_MLS
import TMDB_Clean_Profile
import SwiftUI
import TMDB_Shared_Backend
import Swinject
@available(iOS 15,*)
public struct TMDBAPITabView: View {
    
    @State private var currentIndex = 0
    private let views: [AnyView]
    public init(tmdbKey: String) {
        let container = Container()
        TMDB_Shared_Backend.configure(container: container, apiKey: tmdbKey)
        views =  [
            AnyView(DMSNowPlayingPage(apiKey: tmdbKey)),
            AnyView(TMDB_clean_MLS.MovieListPage(container: container, apiKey: tmdbKey, type: .upcoming)),
            AnyView(ProfilePageVCView(container: container))
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
