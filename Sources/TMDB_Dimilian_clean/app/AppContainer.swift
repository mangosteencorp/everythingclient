import Swinject
class AppContainer {
    static let shared = AppContainer()
    
    let container: Container
    
    private init() {
        container = Container()
        registerDependencies()
    }
    
    private func registerDependencies() {
        container.register(APIService.self) { _ in APIService.shared }.inObjectScope(.container)
        
        container.register(MovieRepository.self) { resolver in
            MovieRepositoryImpl(apiService: resolver.resolve(APIService.self)!)
        }.inObjectScope(.container)
        
        container.register(FetchNowPlayingMoviesUseCase.self) { resolver in
            FetchNowPlayingMoviesUseCase(movieRepository: resolver.resolve(MovieRepository.self)!)
        }
        
        container.register(FetchUpcomingMoviesUseCase.self) { resolver in
            FetchUpcomingMoviesUseCase(movieRepository: resolver.resolve(MovieRepository.self)!)
        }
        
        container.register(MoviesViewModel.self, name: "nowPlaying") { resolver in
            MoviesViewModel(fetchMoviesUseCase: resolver.resolve(FetchNowPlayingMoviesUseCase.self)!)
        }
        
        container.register(MoviesViewModel.self, name: "upcoming") { resolver in
            MoviesViewModel(fetchMoviesUseCase: resolver.resolve(FetchUpcomingMoviesUseCase.self)!)
        }
    }
}
