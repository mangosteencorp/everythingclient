import SwiftUI


//MARK: Profile container view
public struct ProfileView: View {
    
    @EnvironmentObject private var userVM: UserViewModel
    @EnvironmentObject private var movieVM: MoviesViewModel
    
    @State var noUserLogged: Bool = false
    
    public init() {}
    public var body: some View {
        ZStack{
            
            switch noUserLogged{
                
            case true:
                if userVM.isLoading{
                    ProgressView(
                        label: {
                            Text("login_profile_loading",
                                 bundle: Bundle.module) })
                    .progressViewStyle(CustomProgressViewStyle())
                }else {
                    LoginView()
                }
                
            case false:
                if userVM.isLoading{
                    ProgressView(
                        label: { Text("login_profile_loading_user", bundle: Bundle.module) })
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
                        Text("login_load_user_failed", bundle: Bundle.module)
                            .padding()
                        Button(action: {
                            Task{
                                await userVM.getUserInfo()
                                guard userVM.user != nil else {return}
                                await movieVM.fetchFavoritesMovies(accID: "\(userVM.user!.id)")
                                
                            }
                        }, label: {
                            Text("login_cta_reload",
                                 bundle: Bundle.module)})
                        .disabled(userVM.isLoading)
                    }
                }
            }
            
        }
        
        // Checks if there's a session in Keychain. It was done this way to avoid forcing try! in the getSessionID function
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

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(UserViewModel(service: NetworkManager(), keychainM: KeychainManager()))
    }
}
