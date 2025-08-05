import SwiftUI

#if DEBUG
public struct TMDBMovieDetailDemoView: View {
    public init() {}

    public var body: some View {
        VStack {
            Image(systemName: "film")
                .font(.system(size: 60))
                .foregroundColor(.purple)

            Text("TMDB Movie Detail Demo")
                .font(.title)
                .padding()

            Text("This demo will showcase the TMDB Movie Detail functionality")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()

            // TODO: Implement actual TMDB Movie Detail demo
            Text("Coming soon...")
                .font(.caption)
                .foregroundColor(.orange)
        }
        .padding()
    }
}

#if DEBUG
#Preview {
    TMDBMovieDetailDemoView()
}
#endif
#endif