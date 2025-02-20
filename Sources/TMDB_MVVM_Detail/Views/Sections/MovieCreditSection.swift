import SwiftUI
import TMDB_Shared_Backend
struct MovieCreditSection: View {
    let movieId: Int
    @ObservedObject var creditsViewModel: MovieCastingViewModel // avoiding The problem that every time the parent view redraws, a new instance of MovieCastingViewModel is created because it's initialized in the init method. 
    init(movieId: Int, creditsViewModel: MovieCastingViewModel) {
        self.movieId = movieId
        self.creditsViewModel = creditsViewModel
    }
    var body: some View {
        Section {
            switch creditsViewModel.state {
            case .loading:
                RedactedMovieCrosslinePeopleRow()
            case .success(let credits):
                // Display the credits information
                
                MovieCrosslinePeopleRow(title: L10n.castSectionTitle, peoples: credits.cast)
                MovieCrosslinePeopleRow(title: L10n.crewSectionTitle, peoples: credits.crew)
                
                
            case .error(let errorMessage):
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
            }
        }.onFirstAppear {
            creditsViewModel.fetchMovieCredits(movieId: movieId)
        }
    }
    
}
extension Color {
    static func random() -> Color {
        return Color(red: Double.random(in: 0...1), green: Double.random(in: 0...1), blue: Double.random(in: 0...1))
    }
}

extension View {
    @ViewBuilder
    func debugBorder(color: Color? = nil) -> some View {
        #if DEBUG
        self.border(color ?? Color.random(), width: 0.5)
        #else
        self
        #endif
    }
}
struct OnFirstAppearModifier: ViewModifier {
    let perform:() -> Void
    @State private var firstTime: Bool = true
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if firstTime {
                    firstTime = false
                    self.perform()
                }
            }
    }
}




extension View {
    func onFirstAppear( perform: @escaping () -> Void ) -> some View {
        return self.modifier(OnFirstAppearModifier(perform: perform))
    }
}
#Preview {
    MovieCreditSection(movieId: 939243,
                       creditsViewModel: MovieCastingViewModel(
                        apiService: TMDBAPIService(apiKey: "")))
}
