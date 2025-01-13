import SwiftUI
struct MovieOverview : View {
    let movie: Movie
    @State var isOverviewExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.overviewTitle)
                .titleStyle()
                .lineLimit(1)
            Text(movie.overview)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(self.isOverviewExpanded ? nil : 4)
                .onTapGesture {
                    withAnimation {
                        self.isOverviewExpanded.toggle()
                    }
            }
            Button(action: {
                withAnimation {
                    self.isOverviewExpanded.toggle()
                }
            }, label: {
                Text(self.isOverviewExpanded ? L10n.readLess : L10n.readMore)
                    .lineLimit(1)
                    .foregroundColor(.blue)
            })
        }
    }
}
