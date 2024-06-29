import Combine
import Foundation
import SwiftUI
import Swinject

// MARK: - app/AppContainer.swift
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

// MARK: - data/datasource/APIService.swift
public struct APIService {
    let baseURL = URL(string: "https://api.themoviedb.org/3")!
    let apiKey = "1d9b898a212ea52e283351e521e17871"
    public static let shared = APIService()
    let decoder = JSONDecoder()
    
    public enum APIError: Error {
        case noResponse
        case jsonDecodingError(error: Error)
        case networkError(error: Error)
    }
    
    public enum Endpoint {
        case popular, topRated, upcoming, nowPlaying, trending
        case movieDetail(movie: Int), recommended(movie: Int), similar(movie: Int), videos(movie: Int)
        case credits(movie: Int), review(movie: Int)
        case searchMovie, searchKeyword, searchPerson
        case popularPersons
        case personDetail(person: Int)
        case personMovieCredits(person: Int)
        case personImages(person: Int)
        case genres
        case discover
        
        func path() -> String {
            switch self {
            case .popular:
                return "movie/popular"
            case .popularPersons:
                return "person/popular"
            case .topRated:
                return "movie/top_rated"
            case .upcoming:
                return "movie/upcoming"
            case .nowPlaying:
                return "movie/now_playing"
            case .trending:
                return "trending/movie/day"
            case let .movieDetail(movie):
                return "movie/\(String(movie))"
            case let .videos(movie):
                return "movie/\(String(movie))/videos"
            case let .personDetail(person):
                return "person/\(String(person))"
            case let .credits(movie):
                return "movie/\(String(movie))/credits"
            case let .review(movie):
                return "movie/\(String(movie))/reviews"
            case let .recommended(movie):
                return "movie/\(String(movie))/recommendations"
            case let .similar(movie):
                return "movie/\(String(movie))/similar"
            case let .personMovieCredits(person):
                return "person/\(person)/movie_credits"
            case let .personImages(person):
                return "person/\(person)/images"
            case .searchMovie:
                return "search/movie"
            case .searchKeyword:
                return "search/keyword"
            case .searchPerson:
                return "search/person"
            case .genres:
                return "genre/movie/list"
            case .discover:
                return "discover/movie"
            }
        }
    }
    
    public func GET<T: Codable>(endpoint: Endpoint,
                                params: [String: String]?,
                                completionHandler: @escaping (Result<T, APIError>) -> Void) {
        let queryURL = baseURL.appendingPathComponent(endpoint.path())
        var components = URLComponents(url: queryURL, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "language", value: Locale.preferredLanguages[0])
        ]
        if let params = params {
            for (_, value) in params.enumerated() {
                components.queryItems?.append(URLQueryItem(name: value.key, value: value.value))
            }
        }
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        debugPrint(request.curlString)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completionHandler(.failure(.noResponse))
                }
                return
            }
            guard error == nil else {
                DispatchQueue.main.async {
                    completionHandler(.failure(.networkError(error: error!)))
                }
                return
            }
            do {
                let object = try self.decoder.decode(T.self, from: data)
                DispatchQueue.main.async {
                    completionHandler(.success(object))
                }
            } catch let error {
                DispatchQueue.main.async {
#if DEBUG
                    print("JSON Decoding Error: \(error)")
#endif
                    completionHandler(.failure(.jsonDecodingError(error: error)))
                }
            }
        }
        task.resume()
    }
    
    func fetch<T: Decodable>(endpoint: Endpoint, params: [String: String]?) async -> Result<T,APIError> {
        let queryURL = baseURL.appendingPathComponent(endpoint.path())
        var components = URLComponents(url: queryURL, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "language", value: Locale.preferredLanguages[0])
        ]
        if let params = params {
            for (_, value) in params.enumerated() {
                components.queryItems?.append(URLQueryItem(name: value.key, value: value.value))
            }
        }
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        debugPrint(request.curlString)
        do {
            let (data,_) = try await URLSession.shared.data(for: request)
            do {
                let object = try self.decoder.decode(T.self, from: data)
                return .success(object)
            } catch {
                return .failure(.jsonDecodingError(error: error))
            }
        } catch {
            return .failure(.networkError(error: error))
        }
    }
    
    func fetchMovies(endpoint: Endpoint) async -> Result<MovieListResultModel, APIError> {
            return await fetch(endpoint: endpoint, params: ["region": "CA"])
        }
}

extension URLRequest {
    public var curlString: String {
        guard let url = self.url else { return "" }
        var baseCommand = "curl \(url.absoluteString)"
        
        if self.httpMethod == "HEAD" {
            baseCommand += " --head"
        }
        
        var command = [baseCommand]
        
        if let method = self.httpMethod, method != "GET" && method != "HEAD" {
            command.append("-X \(method)")
        }
        
        if let headers = self.allHTTPHeaderFields {
            for (key, value) in headers where key != "Cookie" {
                command.append("-H \"\(key): \(value)\"")
            }
        }
        
        if let bodyData = self.httpBody, let bodyString = String(data: bodyData, encoding: .utf8), !bodyString.isEmpty {
            var escapedBody = bodyString.replacingOccurrences(of: "\"", with: "\\\"")
            escapedBody = escapedBody.replacingOccurrences(of: "`", with: "'")
            command.append("-d \"\(escapedBody)\"")
        }
        
        return command.joined(separator: " ")
    }
}

// MARK: - data/repositories/MovieRepositoryImpl.swift
class MovieRepositoryImpl: MovieRepository {
    private let apiService: APIService
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    func fetchNowPlayingMovies() async -> Result<[Movie], Error> {
        return await fetchMovies(endpoint: .nowPlaying)
    }
    
    func fetchUpcomingMovies() async -> Result<[Movie], Error> {
        return await fetchMovies(endpoint: .upcoming)
    }
    
    private func fetchMovies(endpoint: APIService.Endpoint) async -> Result<[Movie], Error> {
            let result = await apiService.fetchMovies(endpoint: endpoint)
            switch result {
            case .success(let response):
                return .success(response.results.map { self.mapAPIMovieToEntity($0) })
            case .failure(let error):
                return .failure(error)
            }
        }
    
    private func mapAPIMovieToEntity(_ apiMovie: APIMovie) -> Movie {
        // Map API model to domain entity (same as before)
        Movie(id: apiMovie.id,
              title: apiMovie.title,
              overview: apiMovie.overview,
              posterPath: apiMovie.poster_path,
              voteAverage: apiMovie.vote_average,
              popularity: apiMovie.popularity,
              releaseDate: Movie.dateFormatter.date(from: apiMovie.release_date ?? ""))
    }
}

// MARK: - data/models/APIMovie.swift
// API Models

public struct APIMovie: Codable {
    let id: Int
    let title: String
    let overview: String
    let poster_path: String?
    let vote_average: Float
    let popularity: Float
    let release_date: String?
}

// MARK: - data/models/MovieListResponseResultModel.swift
public struct MovieListResultModel: Decodable {
    let dates: Dates
    let page: Int
    public let results: [APIMovie]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case dates, page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

struct Dates: Decodable {
    let maximum: String
    let minimum: String
}

// MARK: - domain/repositories/MovieRepository.swift
// Repository Interface
protocol MovieRepository {
    func fetchNowPlayingMovies() async -> Result<[Movie], Error>
    func fetchUpcomingMovies() async -> Result<[Movie], Error>
}

// MARK: - domain/usecase/FetchMoviesUseCase.swift
protocol FetchMoviesUseCase {
    func execute() async -> Result<[Movie], Error>
}

// MARK: - domain/usecase/FetchUpcomingMovieUseCase.swift
class FetchUpcomingMoviesUseCase: FetchMoviesUseCase {
    private let movieRepository: MovieRepository
    
    init(movieRepository: MovieRepository) {
        self.movieRepository = movieRepository
    }
    
    func execute() async -> Result<[Movie], Error> {
        return await movieRepository.fetchUpcomingMovies()
    }
}

// MARK: - domain/usecase/FetchNowPlayingMoviesUseCase.swift
class FetchNowPlayingMoviesUseCase: FetchMoviesUseCase {
    private let movieRepository: MovieRepository
    
    init(movieRepository: MovieRepository) {
        self.movieRepository = movieRepository
    }
    
    func execute() async -> Result<[Movie], Error> {
        return await movieRepository.fetchNowPlayingMovies()
    }
}

// MARK: - domain/entities/Movie.swift
// Entities

struct Movie {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let voteAverage: Float
    let popularity: Float
    let releaseDate: Date?
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

// MARK: - presentation/view_models/MoviesViewModel.swift
class MoviesViewModel: ObservableObject {
    @Published var movies: [Movie] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let fetchMoviesUseCase: FetchMoviesUseCase
    
    init(fetchMoviesUseCase: FetchMoviesUseCase) {
        self.fetchMoviesUseCase = fetchMoviesUseCase
    }
    
    func fetchMovies() {
        isLoading = true
        errorMessage = nil
        
        Task {
            let result = await fetchMoviesUseCase.execute()
            await MainActor.run {
                self.isLoading = false
                switch result {
                case .success(let movies):
                    self.movies = movies
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - presentation/pages/MovieListView.swift
public struct MovieListView: View {
    @StateObject private var viewModel: MoviesViewModel
    let type: MovieListType
    
    public init(type: MovieListType) {
        let container = AppContainer.shared.container
        let viewModel: MoviesViewModel
        switch type {
        case .nowPlaying:
            viewModel = container.resolve(MoviesViewModel.self, name: "nowPlaying")!
        case .upcoming:
            viewModel = container.resolve(MoviesViewModel.self, name: "upcoming")!
        }
        _viewModel = StateObject(wrappedValue: viewModel)
        self.type = type
    }
    
    public var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                } else {
                    List(viewModel.movies, id: \.id) { movie in
                        MovieRow(movie: movie)
                    }
                }
            }
            .navigationTitle(type.title)
            .onAppear {
                viewModel.fetchMovies()
            }
        }
    }
}
public enum MovieListType {
    case nowPlaying
    case upcoming
    
    var title: String {
        switch self {
        case .nowPlaying:
            return "Now Playing"
        case .upcoming:
            return "Upcoming"
        }
    }
    
    var iconName: String {
        switch self {
        case .nowPlaying:
            return "play.circle"
        case .upcoming:
            return "calendar"
        }
    }
}

#Preview {
    MovieListView(type: .upcoming)
}

// MARK: - presentation/widgets/PopularityBadge.swift
//
//  PopularityBadge.swift
//  MovieSwift
//
//  Created by Thomas Ricouard on 16/06/2019.
//  Copyright © 2019 Thomas Ricouard. All rights reserved.
//



public struct PopularityBadge : View {
    public let score: Int
    public let textColor: Color
    
    @State private var isDisplayed = false
    
    public init(score: Int, textColor: Color = .primary) {
        self.score = score
        self.textColor = textColor
    }
    
    var scoreColor: Color {
        get {
            if score < 40 {
                return .red
            } else if score < 60 {
                return .orange
            } else if score < 75 {
                return .yellow
            }
            return .green
        }
    }
    
    var overlay: some View {
        ZStack {
            Circle()
                .trim(from: 0,
                      to: isDisplayed ? CGFloat(score) / 100 : 0)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [1]))
                .foregroundColor(scoreColor)
                .animation(Animation.interpolatingSpring(stiffness: 60, damping: 10).delay(0.1))
        }
        .rotationEffect(.degrees(-90))
        .onAppear {
            self.isDisplayed = true
        }
    }
    
    public var body: some View {
        ZStack {
            Circle()
                .foregroundColor(.clear)
                .frame(width: 40)
                .overlay(overlay)
                .shadow(color: scoreColor, radius: 4)
            Text("\(score)%")
                .font(Font.system(size: 10))
                .fontWeight(.bold)
                .foregroundColor(textColor)
            }
            .frame(width: 40, height: 40)
    }
}

#if DEBUG
struct PopularityBadge_Previews : PreviewProvider {
    static var previews: some View {
        VStack {
            PopularityBadge(score: 80)
            PopularityBadge(score: 10)
            PopularityBadge(score: 30)
            PopularityBadge(score: 50)
        }
    }
}
#endif

// MARK: - presentation/widgets/MovieRow.swift
fileprivate let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()


struct MoviePosterImage: View {
    var posterPath: String?
    var posterSize: PosterSize

    var body: some View {
        if let posterPath = posterPath, let url = URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)") {
            if #available(iOS 15.0, *) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: posterSize.width, height: posterSize.height)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: posterSize.width, height: posterSize.height)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: posterSize.width, height: posterSize.height)
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                            .frame(width: posterSize.width, height: posterSize.height)
                    }
                }
            } else {
                CustomImageView(imageURL: url)
            }
        } else {
            Image(systemName: "photo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: posterSize.width, height: posterSize.height)
                .foregroundColor(.gray)
        }
    }

}

struct PosterSize {
    var width: CGFloat
    var height: CGFloat
    
    static let medium = PosterSize(width: 100, height: 150)
}


struct TitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline) // Set the font to headline
            .foregroundColor(.primary) // Set the text color to primary
            .padding(.vertical, 4) // Add vertical padding
    }
}

extension View {
    func titleStyle() -> some View {
        self.modifier(TitleStyle())
    }
}

@available(iOS 13, macOS 10.15, *)
extension Color {
    static let steamGold = Color(red: 199 / 255, green: 165 / 255, blue: 67 / 255)
}


@available(iOS 14, macOS 11, *)
struct MovieRow: View {
    let movie: Movie
    var displayListImage = true

    var body: some View {
        HStack {
            ZStack(alignment: .topLeading) {
                MoviePosterImage(posterPath: movie.posterPath ?? "",
                                 posterSize: .medium)
                    .redacted(if: movie.posterPath == nil)
            }
            .fixedSize()
            .animation(.spring())
            VStack(alignment: .leading, spacing: 8) {
                Text(movie.title)
                    .titleStyle()
                    .foregroundColor(Color.steamGold)
                    .lineLimit(2)
                HStack {
                    PopularityBadge(score: Int(movie.voteAverage * 10))
                    Text(formatter.string(from: movie.releaseDate ?? Date()))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                Text(movie.overview)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .truncationMode(.tail)
            }.padding(.leading, 8)
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
        .contextMenu { Text(self.movie.id.description) }
        .redacted(if: movie.id == 0)
    }
}


@available(iOS 13, macOS 11, *)
extension View {
    @ViewBuilder
    func redacted(if condition: @autoclosure () -> Bool) -> some View {
        redacted(reason: condition() ? .placeholder : [])
    }
}

// MARK: - presentation/widgets/ImageView.swift
class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    private var cancellable: AnyCancellable?
    
    func load(fromURL url: URL) {
        cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map { UIImage(data: $0.data) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .assign(to: \.image, on: self)
    }
}

@available(iOS 14.0, *)
struct CustomImageView: View {
    @StateObject private var loader = ImageLoader()
    let imageURL: URL

    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            loader.load(fromURL: imageURL)
        }
        .frame(width: 100, height: 100)
    }
}

