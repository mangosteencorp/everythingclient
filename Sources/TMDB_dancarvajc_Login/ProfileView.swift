import SwiftUI


//MARK: Vista contenedora de perfil
public struct ProfileView: View {
    
    @EnvironmentObject private var userVM: UserViewModel
    @EnvironmentObject private var movieVM: MoviesViewModel
    
    @State var noUserLogged: Bool = true
    
    public init() {}
    public var body: some View {
        ZStack{
            
            switch noUserLogged{
                
            case true:
                if userVM.isLoading{
                    ProgressView("Loading...")
                        .progressViewStyle(CustomProgressViewStyle())
                }else {
                    LoginView()
                }
                
            case false:
                if userVM.isLoading{
                    ProgressView("Loading user...")
                        .progressViewStyle(CustomProgressViewStyle())
                    
                } else if userVM.user != nil {
                    UserView(user: userVM.user!)
                        .onAppear {
                            Task{
                                await movieVM.fetchFavoritesMovies(accID: "\(userVM.user!.id)")
                            }
                        }

                }else{
                    VStack{
                        Text("Could not load your user")
                            .padding()
                        Button("Reload"){
                            Task{
                                await userVM.getUserInfo()
                                guard userVM.user != nil else {return}
                                await movieVM.fetchFavoritesMovies(accID: "\(userVM.user!.id)")
                                
                            }
                        }.disabled(userVM.isLoading)
                    }
                }
            }
            
        }
        
        //Comprueba que haya alguna session en Keychain. Se hizo de esta forma para no forzar el try! en la función getSessionID
        .onAppear(perform: {
            let newValue = try? userVM.keychainM.getSessionID() == ""
            if newValue != nil{
                noUserLogged = newValue!
            }

        })
        .onChange(of: try? userVM.keychainM.getSessionID() == "", perform: { newValue in

            if newValue != nil{
                withAnimation {
                    noUserLogged = newValue!
                }
             
            }
        })
        
    }
}

public struct ProfileTabView: View {
    let networkManager = NetworkManager()
    let keychainManager = KeychainManager()
    
    public init(){}
    public var body: some View {
        ProfileView()
            .environmentObject(UserViewModel(service: networkManager, keychainM: keychainManager))
            .environmentObject(MoviesViewModel(service: networkManager, keychainM: keychainManager))
            .environmentObject(NetworkViewModel(networkMg: networkManager))
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(UserViewModel(service: NetworkManager(), keychainM: KeychainManager()))
    }
}
