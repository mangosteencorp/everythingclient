import SwiftUI
import TMDB_Shared_UI

struct MovieCrosslinePeopleRow : View {
    let title: String
    let peoples: [People]
    
    private var peoplesListView: some View {
        List(peoples) { cast in
            PeopleListItem(people: cast)
        }.navigationBarTitle(title)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .titleStyle()
                    .padding(.leading)
                NavigationLink(destination: peoplesListView,
                               label: {
                    Text(L10n.seeAll).foregroundColor(.blue)
                })
            }
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    ForEach(peoples) { cast in
                        PeopleRowItem(people: cast)
                    }
                }.padding(.leading)
            }
        }
        .listRowInsets(EdgeInsets())
        .padding(.vertical)
    }
    
}

struct RedactedMovieCrosslinePeopleRow: View {
    var body: some View {
        MovieCrosslinePeopleRow(
            title: L10n.castSectionTitle,
            peoples: [
                People.redacted(),
                People.redacted(),
                People.redacted(),
                People.redacted(),
                People.redacted(),
                People.redacted()
            ])
        .redacted(reason: .placeholder)
    }
}

struct PeopleListItem: View {
    let people: People
    
    var body: some View {
        NavigationLink(destination: EmptyView()) {
            HStack {
                RemoteTMDBImage(posterPath: people.profile_path, posterSize: .medium, image: .cast)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(people.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Text(people.character ?? people.department ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }// .contextMenu{ PeopleContextMenu(people: people.id) }
        }
    }
}

struct PeopleRowItem: View {
    let people: People
    
    var body: some View {
        NavigationLink(destination: EmptyView()) {
            VStack(alignment: .center) {
                RemoteTMDBImage(posterPath: people.profile_path, posterSize: .medium, image: .cast)
                Text(people.name)
                    .font(.footnote)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(people.character ?? people.department ?? "")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 100)
            // .contextMenu{ PeopleContextMenu(people: people.id) }
        }
    }
}
#if DEBUG
#Preview {
    return MovieCrosslinePeopleRow(title: "Cast", peoples: examplePeoples)
}

#Preview {
    return RedactedMovieCrosslinePeopleRow()
}
#endif
