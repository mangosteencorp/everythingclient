import SwiftUI

struct MovieCreditSection: View {
    let movieId: Int
    @StateObject fileprivate var creditsViewModel = MovieCastingViewModel()
    
    var body: some View {
        Section {
            switch creditsViewModel.state {
            case .loading:
                ProgressView(L10n.playingLoading)
            case .success(let credits):
                // Display the credits information
                
                MovieCrosslinePeopleRow(title: L10n.castSectionTitle, peoples: credits.cast)
                MovieCrosslinePeopleRow(title: L10n.castSectionTitle, peoples: credits.crew)
                
                
            case .error(let errorMessage):
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
            }
        }
        .onAppear {
            // Assuming you have a way to pass the movieId
            creditsViewModel.fetchMovieDetail(movieId: movieId)
        }
    }
    
}
