import SwiftUI
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
                    // TODO: localization
                    Text("See all").foregroundColor(.blue)
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

#Preview {
    let examplePeoples = [
        People(id: 3416, name: "Demi Moore", character: "Elisabeth", department: nil, profile_path: "/brENIHiNrGUpoBMPqIEQwFNdIsc.jpg", known_for_department: "Acting", known_for: nil, also_known_as: nil, birthDay: nil, deathDay: nil, place_of_birth: nil, biography: nil, popularity: 57.714, images: nil),
        People(id: 6065, name: "Dennis Quaid", character: "Harvey", department: nil, profile_path: "/lMaDAJHzsKH7U3dln2B3kY3rOhE.jpg", known_for_department: "Acting", known_for: nil, also_known_as: nil, birthDay: nil, deathDay: nil, place_of_birth: nil, biography: nil, popularity: 51.034, images: nil),
        People(id: 45849, name: "Christian Erickson", character: "Man at Diner", department: nil, profile_path: "/cpEzQNW1EsRmK8SMj4y5xwevXwM.jpg", known_for_department: "Acting", known_for: nil, also_known_as: nil, birthDay: nil, deathDay: nil, place_of_birth: nil, biography: nil, popularity: 5.673, images: nil),
        People(id: 73995, name: "Céline Vogt", character: "Elisabeth (Young) - Walk of Fame", department: nil, profile_path: "/2pkBIL8OKXXWr1SERPsr7LVAsQX.jpg", known_for_department: "Acting", known_for: nil, also_known_as: nil, birthDay: nil, deathDay: nil, place_of_birth: nil, biography: nil, popularity: 0.882, images: nil),
        People(id: 158124, name: "Shane Sweet", character: "Additional Voices", department: nil, profile_path: "/3fVAoIbfMO2XKtMsIOVpo5fkXVq.jpg", known_for_department: "Acting", known_for: nil, also_known_as: nil, birthDay: nil, deathDay: nil, place_of_birth: nil, biography: nil, popularity: 3.185, images: nil)
    ]
    
    return MovieCrosslinePeopleRow(title: "Cast", peoples: examplePeoples)
        
}
