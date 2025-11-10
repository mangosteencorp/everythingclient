# Pull-to-Refresh & Clean Architecture Fix - Industry Practices & APIs Used

## Industry Practices Used:
- **UIRefreshControl**: Standard iOS pull-to-refresh component following Apple Human Interface Guidelines
- **Delegate Pattern**: Decoupled refresh communication between view controllers using delegate protocols  
- **Clean Architecture**: Proper layer separation with Use Cases, Repository pattern, and dependency injection
- **Repository Pattern**: Abstract data access through interfaces with concrete implementations
- **Use Case Pattern**: Encapsulated business logic with single responsibility (ToggleTVShowFavoriteUseCase)
- **Dependency Injection**: Swinject container for loose coupling and testability
- **RxSwift/Combine**: Reactive state management for UI updates and data flow
- **View State Management**: Centralized UI state handling (loading, loaded, error, unauthorized)
- **Optimistic UI Updates**: Immediate UI feedback with rollback on API failure
- **Diffable Data Source**: Modern UICollectionView data management with animations and performance optimization

## Apple/3rd Party APIs Used:
- **UIRefreshControl** - Native iOS pull-to-refresh control with `addTarget` and `endRefreshing()` methods
- **RxSwift BehaviorRelay** - For reactive state management and UI binding with `asObservable()` and `accept()`
- **UICollectionViewDiffableDataSource** - For performant collection view updates with `apply()` method
- **Combine Publishers** - For authentication state observation with `.sink()` and `.receive(on:)`
- **Swinject** - Dependency injection container for Clean Architecture implementation
- **TMDB API** - Proper use of `/account/{id}/favorite` endpoint with correct `media_type: "tv"` for TV shows