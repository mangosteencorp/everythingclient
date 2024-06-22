protocol FetchMoviesUseCase {
    func execute() async -> Result<[Movie], Error>
}
