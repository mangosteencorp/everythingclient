import SwiftUI

struct TMDBTVShowDetailDemoView: View {
    var body: some View {
        VStack {
            Image(systemName: "tv")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("TMDB TV Show Detail Demo")
                .font(.title)
                .padding()

            Text("This demo will showcase the TMDB TV Show Detail functionality")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()

            // TODO: Implement actual TMDB TV Show Detail demo
            Text("Coming soon...")
                .font(.caption)
                .foregroundColor(.orange)
        }
        .padding()
    }
}

#if DEBUG
#Preview {
    TMDBTVShowDetailDemoView()
}
#endif