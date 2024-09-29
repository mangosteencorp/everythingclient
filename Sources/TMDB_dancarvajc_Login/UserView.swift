import SwiftUI
import NukeUI


struct UserView: View {
    @EnvironmentObject private var userVM: UserViewModel
    @EnvironmentObject private var movieVM: MoviesViewModel
    @EnvironmentObject private var networkVM: NetworkViewModel
    let user: UserModel
    
    var body: some View {
        
        GeometryReader { g in
            VStack{
                VStack{
                    //MARK: User profile picture
                    LazyImage(url: URL(string: Constants.gravatarURL + user.avatar.gravatar.hash)!)
                        .onCompletion(Constants.onCompletionLazyImage(networkVM: networkVM))
                        .aspectRatio(contentMode: .fit)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.white, lineWidth: 4))
                        .shadow(radius: 5)
                        .frame(width: 100, height: 100)
                    //MARK: Welcome message
                    Text("login_user_welcome \(user.username)",
                         bundle: Bundle.module)
                        .padding(.top,5)
                    //MARK: Log out button
                    Button(action: {
                        Task{
                            await userVM.logOut()
                        }
                    }, label: {
                        Text("login_btn_logout", bundle: Bundle.module)
                    }).padding(5)
                    Divider()
                    Text("login_section_favourites", bundle: Bundle.module)
                        .font(.title)
                        .bold()
                    
                }.frame(width: g.size.width, height: g.size.height*0.4)
                
                //MARK: List of favorite movies
                if movieVM.favoritesMovies.count != 0 {
                    List(movieVM.favoritesMovies){ movie in
                        HStack{
                            Text(movie.title)
                        }.frame(maxWidth:.infinity, maxHeight:.infinity, alignment: .center)
                        
                    }.padding(.top,5)
                        .frame(width: g.size.width, height: g.size.height*0.6)
                        .listStyle(.plain)
                }else if movieVM.isLoading {
                    ProgressView()
                        .padding()
                }else{
                    //If loading fails for any reason, a button is shown to try again
                    if movieVM.isLoading {
                        ProgressView()
                            .padding()
                    }
                    Button(action: {
                        Task{
                            await movieVM.fetchFavoritesMovies(accID: "\(userVM.user!.id)")
                        }
                        
                    }, label: {
                        Text("login_cta_reload_list", bundle: Bundle.module)
                    }).padding()
                        .disabled(movieVM.isLoading)
                }
                
            }
        }.animation(.default)
        .padding()
    }
}

struct UserView_Previews: PreviewProvider {
    static var previews: some View {
        UserView(user: UserModel(avatar: .init(gravatar: .init(hash: "asdasdasdas")), id: 6595, iso639_1: "asdasdas", iso3166_1: "asdasd", name: "Danny", includeAdult: true, username: "Danny CC"))
            .environmentObject(UserViewModel(service: NetworkManager(), keychainM: KeychainManager()))
            .environmentObject(MoviesViewModel(service: NetworkManager(), keychainM: KeychainManager()))
            .environmentObject(NetworkViewModel(networkMg: NetworkManager()))
    }
}
