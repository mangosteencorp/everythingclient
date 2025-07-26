import SwiftUI

struct PokedexDetailDemoView: View {
    var body: some View {
        VStack {
            Image(systemName: "leaf")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("Pokedex Detail Demo")
                .font(.title)
                .padding()

            Text("This demo will showcase the Pokedex Detail functionality")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()

            // TODO: Implement actual Pokedex Detail demo
            Text("Coming soon...")
                .font(.caption)
                .foregroundColor(.orange)
        }
        .padding()
    }
}

#if DEBUG
#Preview {
    PokedexDetailDemoView()
}
#endif