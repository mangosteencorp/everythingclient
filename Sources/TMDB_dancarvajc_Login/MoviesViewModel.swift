
import Foundation
import SwiftUI
import AuthenticationServices

public class MoviesViewModel: NSObject, ObservableObject {
    
    @Published var movies: [FullMovieModel] = []
    @Published var favoritesMovies: [MovieModel] = []
    @Published var topRatedMovies: [FullMovieModel] = []
    @Published var searchedMovies: [FullMovieModel] = []
    private let service: NetworkManager
    private let keychainM: KeychainManager
    
    
    @Published var isLoading: Bool = false
    @Published var alertMessage:String = ""
    @Published var showAlert = false
    
    init(service: NetworkManager, keychainM: KeychainManager) {
        
        self.service = service
        self.keychainM = keychainM
    }
    
    
    //MARK: Permite poner o sacar de favoritos una película
    @MainActor func setFavoriteMovie(accID: String, idMovie: Int, favorite: Bool) async -> Bool {
        
        var result = false
        do {
            let request = try EndPoint.createURLRequest(url: .setfavoriteMovie(accID), method: .POST, query: ["api_key":EndPoint.apiKey,"session_id":keychainM.getSessionID()], parameters: ["media_type":"movie", "media_id": idMovie, "favorite": favorite])
            
            let resp : FavResp = try await service.makeHTTPRequest(url: request)
            print("ESTATOS FAV:")
            print(resp.statusMessage)
            result = true
            service.noInternet = false
            await fetchFavoritesMovies(accID: accID)
            
        } catch  {
            loadError(error)
        }
        return result
    }
    
    //MARK: Recopila las películas de acuerdo al tipo que se ponga (ROUTE)
    @MainActor func fetchMovies(of type: Route, search: String = "") async {
      //  guard isLoading == false else{return}
        isLoading = true
        
        do {
            //Se genera la URL
            let urlRequest = try EndPoint.createURLRequest(url: type, method: .GET, query: type == .searchMovie ? ["api_key" : EndPoint.apiKey, "language":"es-mx","query":search] : ["api_key" : EndPoint.apiKey, "language":"es-mx"])
            
            //Se hace la petición HTTP
            let movies: MoviesResp = try await service.makeHTTPRequest(url: urlRequest)
            
            //De manera paralela se obtiene la información de cada película, se decodifica y se genera los modelos (objetos) de las películas
            let resultadoFinal = try await withThrowingTaskGroup(of: FullMovieModel.self, returning: [FullMovieModel].self, body: { grouptask in
                
                for movie in movies.results {
                    grouptask.addTask {
                        let urlRequest = try EndPoint.createURLRequest(url: .movie("\(movie.id)"), method: .GET, query: ["api_key" : EndPoint.apiKey, "append_to_response": "credits", "language":"es-mx"])
                        let fullMovie: FullMovieModel = try await self.service.makeHTTPRequest(url: urlRequest)
                        return fullMovie
                    }
                }
                
                var childTaskResults:[FullMovieModel] = []
                
                for try await result in grouptask {
                    childTaskResults.append(result)
                }
                
                return childTaskResults
                
            })

       
            
        } catch  {
            loadError(error)
        }
        
    }
    
    //MARK: Se obtienen las películas marcadas en favoritos del usuario
    @MainActor func fetchFavoritesMovies(accID: String) async {
        // guard isLoading == false else {return}
       // isLoading = true
        
        do {
            let urlRequest = try EndPoint.createURLRequest(url: .getFavoritesMovies(accID), method: .GET, query: ["api_key" : EndPoint.apiKey,"session_id":keychainM.getSessionID(), "language":"es-mx"])
            
            let movies: FavoritesMoviesResp = try await service.makeHTTPRequest(url: urlRequest)
            
            self.favoritesMovies = movies.results
            
          //  isLoading = false
        } catch  {
            loadError(error)
        }
    }
    
    //MARK: Función que carga los errores si los hubiere
    @MainActor private func loadError(_ error: Error){
        isLoading = false
        alertMessage = error.localizedDescription
        showAlert = true
    }
    
    
}



