import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

@available(iOS 16.0, *)
struct MovieCrosslinePeopleRow<Route: Hashable>: View {
    let title: String
    let peoples: [People]
    let personRouteBuilder: ((Int) -> Route)?

    private var peoplesListView: some View {
        List(peoples) { cast in
            PeopleListItem(people: cast, personRouteBuilder: personRouteBuilder)
        }.navigationBarTitle(title)
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .titleStyle()
                    .padding(.leading)
                NavigationLink(
                    destination: peoplesListView,
                    label: {
                        Text(L10n.seeAll).foregroundColor(.blue)
                    }
                )
            }
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    ForEach(peoples) { cast in
                        PeopleRowItem(people: cast, personRouteBuilder: personRouteBuilder)
                    }
                }.padding(.leading)
            }
        }
        .listRowInsets(EdgeInsets())
        .padding(.vertical)
    }
}

@available(iOS 16.0, *)
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
                People.redacted(),
            ],
            personRouteBuilder: nil as ((Int) -> Int)?
        )
        .redacted(reason: .placeholder)
    }
}

@available(iOS 16.0, *)
struct PeopleListItem<Route: Hashable>: View {
    let people: People
    let personRouteBuilder: ((Int) -> Route)?

    var body: some View {
        if let routeBuilder = personRouteBuilder {
            NavigationLink(value: routeBuilder(people.id)) {
                content
            }
        } else {
            content
        }
    }

    private var content: some View {
        HStack {
            RemoteTMDBImage(posterPath: people.profilePath, imageSize: .profileMedium)
                .frame(width: PosterSize.medium.width, height: PosterSize.medium.height)

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
        } // .contextMenu{ PeopleContextMenu(people: people.id) }
    }
}

@available(iOS 16.0, *)
struct PeopleRowItem<Route: Hashable>: View {
    let people: People
    let personRouteBuilder: ((Int) -> Route)?

    var body: some View {
        if let routeBuilder = personRouteBuilder {
            NavigationLink(value: routeBuilder(people.id)) {
                // Same value as the link's, so the person page zooms out of this item.
                content.zoomTransitionSource(id: routeBuilder(people.id))
            }
        } else {
            content
        }
    }

    private var content: some View {
        VStack(alignment: .center) {
            RemoteTMDBImage(posterPath: people.profilePath, imageSize: .profileMedium)
                .frame(width: PosterSize.medium.width, height: PosterSize.medium.height)
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

#if DEBUG
@available(iOS 16.0, *)
#Preview {
    return MovieCrosslinePeopleRow(title: "Cast", peoples: examplePeoples, personRouteBuilder: { $0 })
}

@available(iOS 16.0, *)
#Preview {
    return RedactedMovieCrosslinePeopleRow()
}
#endif
