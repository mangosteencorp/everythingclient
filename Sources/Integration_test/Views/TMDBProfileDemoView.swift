import SwiftUI

struct TMDBProfileDemoView: View {
    var body: some View {
        VStack {
            Image(systemName: "person.circle")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("TMDB Profile Demo")
                .font(.title)
                .padding()

            Text("This demo will showcase the TMDB Profile functionality")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()

            // TODO: Implement actual TMDB Profile demo
            Text("Coming soon...")
                .font(.caption)
                .foregroundColor(.orange)
        }
        .padding()
    }
}

#if DEBUG
#Preview {
    TMDBProfileDemoView()
}
#endif