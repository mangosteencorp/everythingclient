# everythingclient Guidelines


## Architecture & Reactive Models by Module

### TMDB Modules

#### TMDB_Discover
- **Architecture**: Clean Architecture
- **Reactive Model**: Combine (ObservableObject, @Published)
- **Structure**:
  - `app/`: Dependency injection (Swinject)
  - `data/`: Data layer (API services, repositories, models)
  - `domain/`: Business logic (entities, use cases, repositories)
  - `presentation/`: UI layer (views, view models)

#### TMDB_Feed
- **Architecture**: MVVM
- **Reactive Model**: Combine (ObservableObject, @Published)
- **Structure**:
  - `ViewModels/`: MVVM view models
  - `Views/`: Views and pages
  - `Model/`: Data models
  - `Backend/`: API service protocols

#### TMDB_Profile
- **Architecture**: Clean Architecture
- **Reactive Model**: Combine (ObservableObject, @Published)
- **Structure**:
  - `Data/`: Data layer (repositories, models)
  - `Domain/`: Business logic (entities, use cases)
  - `Presentation/`: UI layer (view controllers, view models)
  - `DI/`: Dependency injection

#### TMDB_MovieDetail
- **Architecture**: MVVM
- **Reactive Model**: Combine (ObservableObject, @Published)
- **Structure**:
  - `ViewModels/`: MVVM view models
  - `Views/`: Views and pages
  - `Model/`: Data models

#### TMDB_TVShowDetail
- **Architecture**: Data Store pattern
- **Reactive Model**: Combine (ObservableObject, @Published)
- **Structure**:
  - `View/`: Views
  - `StatelessWidgets/`: Reusable components
  - `Entities/`: Data models

### Pokedex Modules

#### Pokedex_Pokelist
- **Architecture**: VIPER
- **Reactive Model**: Traditional delegate pattern
- **Structure**:
  - `View/`: View controllers
  - `Presenter/`: Business logic and view updates
  - `Interactor/`: Data operations
  - `Entities/`: Data models
  - `Protocols/`: VIPER protocols
  - `Router/`: Navigation logic

#### Pokedex_Detail
- **Architecture**: MVVM
- **Reactive Model**: RxSwift (BehaviorRelay, PublishRelay)
- **Structure**:
  - `View/`: View controllers
  - `ViewModel/`: MVVM view models with RxSwift

### Shared Modules

#### TMDB_Shared_Backend
- **Architecture**: Service layer pattern
- **Reactive Model**: Combine for authentication state
- **Structure**:
  - `Service/`: API services
  - `data/`: Data models and repositories
  - `domain/`: Domain entities
  - `presentation/`: Shared view models

#### TMDB_Shared_UI
- **Architecture**: Component-based architecture
- **Reactive Model**: SwiftUI native reactive
- **Structure**:
  - `Views/`: Reusable components
  - `ViewModifier/`: Custom view modifiers

## Routing

### TMDB Routing
TMDB uses a **Coordinator pattern** with **NavigationStack** for routing:

#### Coordinator Structure
- `Coordinator.swift`: Manages tab selection and navigation states
- `NavigationState.swift`: Tracks navigation paths per tab
- `Route/TMDBRoute.swift`: Defines route types (movieDetail, tvShowDetail, movieList)

#### Navigation Flow
```swift
// Coordinator manages navigation
coordinator.navigate(to: .movieDetail(movie), in: .movieFeed)
coordinator.pop(in: .movieFeed)
coordinator.popToRoot(in: .movieFeed)

// NavigationStack binding
NavigationStack(path: coordinator.path(for: .movieFeed)) {
    // Views
}
```

#### Route Types
- `movieDetail(MovieRouteModel)`: Navigate to movie detail
- `tvShowDetail(Int)`: Navigate to TV show detail  
- `movieList(AdditionalMovieListParams)`: Navigate to movie list

### Pokedex Routing
Pokedex uses **VIPER Router pattern** with **UIKit navigation**:

#### Router Structure
- `PokelistRouter.swift`: Creates modules and handles navigation
- `PokelistRouterProtocol.swift`: Defines router interface

#### Navigation Flow
```swift
// Router creates module
let viewController = PokelistRouter.createModule(pokemonService: service)

// Router handles navigation
router.navigateToPokemonDetail(from: viewController, with: pokemonId)
```

#### Module Creation
- Router assembles VIPER components (View, Presenter, Interactor)
- Router handles navigation between modules
- Uses UIKit `pushViewController` for navigation

## Testing

### Using Test Scripts

#### Build for Testing
```bash
# Build specific module for testing
scheme=TMDB_Discover bash .github/scripts/build.sh
scheme=TMDB_Feed bash .github/scripts/build.sh
scheme=Pokedex_Pokelist bash .github/scripts/build.sh
```

DO NOT USE `swift test`, this project is not available for MacOS

#### Run Tests with Coverage
```bash
# Run all tests with coverage reporting
bash .github/scripts/test.sh

# Available test schemes:
# - TMDB_Discover_Tests
# - TMDB_Feed_Tests  
# - TMDB_Shared_Backend_Tests
```

#### Coverage Requirements
- **Target**: 100% code coverage for all modules
- **Reports**: Generated in `.output/coverage_report.txt`
- **Ignored**: Test files, generated files, dependencies

## Preview Requirements

### Every View Must Have Previews
All views, view controllers, and widgets must include comprehensive previews with example data.

### Preview Patterns

#### SwiftUI Views
```swift
#if DEBUG
#Preview {
    YourView()
        .previewDisplayName("Default State")
}

#Preview("Loading State") {
    YourView()
        .environmentObject(LoadingState())
}
#endif
```

#### UIKit View Controllers
```swift
#if DEBUG
#Preview {
    YourViewController()
}
#endif
```

UIViewControllerPreview is ready at Sources/Shared_UI_Support/UIViewControllerPreview.swift for Preview with PreviewProvider

#### Example Data Generation
```swift
#if DEBUG
// Generate comprehensive example data
let exampleMovie = Movie(
    id: 1,
    title: "Example Movie",
    overview: "This is an example movie for previews",
    posterPath: "/example.jpg",
    voteAverage: 8.5,
    popularity: 100.0,
    releaseDate: Date()
)

// Use in previews
#Preview {
    MovieDetailView(movie: exampleMovie)
}
#endif
```

### Preview Data Requirements
- **Realistic Data**: Use realistic example data that represents actual API responses
- **Multiple States**: Show loading, success, error, and empty states
- **Edge Cases**: Include edge cases like long text, missing images, etc.
- **Accessibility**: Test with different accessibility settings
- **Dark/Light Mode**: Show both color schemes when applicable

## Code Style
- Architecture: Mix of VIPER, Clean Architecture, and MVVM
- Module organization: Feature-based (TMDB, Pokedex)
- Naming: PascalCase for types, camelCase for properties/methods
- Imports: Keep organized by framework then feature modules
- Protocols: End with '-Protocol' or describe behavior ('-able')
- Error handling: Use domain-specific errors and optionals appropriately
- UI: Supports both SwiftUI and UIKit with shared theming
- Testing: Aim for high coverage, use protocol mocking

## Dependencies
- DI: Swinject
- Reactive: RxSwift, Combine
- Networking: Apollo (GraphQL), URLSession
- Images: Kingfisher
- Testing: ViewInspector
- UI: SwiftUI, UIKit, SnapKit