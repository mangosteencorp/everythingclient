import SwiftUI

@available(iOS 16.0, *)
struct MovieLocations: View {
    let locations: [String]

    init(locations: [String]) {
        self.locations = locations
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.locationsTitle)
                .titleStyle()
                .padding(.leading)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(locations, id: \.self) { location in
                        RoundedBadge(text: location, color: .blue, useGradient: true)
                    }
                }.padding(.leading)
            }
        }
        .listRowInsets(EdgeInsets())
        .padding(.vertical)
    }
}

#if DEBUG
@available(iOS 16.0, *)
#Preview {
    MovieLocations(locations: [
        "Los Angeles",
        "New York",
        "London",
        "Paris",
        "Tokyo",
        "Peru",
        "Amazon Rainforest",
    ])
}
#endif
