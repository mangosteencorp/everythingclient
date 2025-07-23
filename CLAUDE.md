# everythingclient Guidelines

Be brutally honest, don't be a yes man. 
If I am wrong, point it out bluntly. 
I need honest feedback on my code.

## Architecture & Reactive Models by Module

- This is an iOS project using Xcode workspace, feature based modularization
- Each module has a different architecture (such as MVVM, Clean architecture, ...)
- Main scheme: EverythingClient

Common module folder structure:
- Previews: SwiftUI preview for the main view in folder, using real api key

### Build Commands
When building for testing, use the Xcode build script instead of `swift build`, replace `EverythingClient` with the target I'm currently working on:
```bash
scheme=EverythingClient bash .github/scripts/build.sh
```

### Project Structure
- This is an iOS project using Xcode workspace, feature based modularization
- Each module has a different architecture (such as MVVM, Clean architecture, ...)
- Main scheme: EverythingClient

### Development Guidelines
- when working on a module, look at the structure of the module to see if whether it is mainly SwiftUI or RxSwift or UIKit, and what the architecture is (MVVM, Clean, ...) before start writing code
- look at root level **Package.swift** first to know the dependencies before start implementation

### TMDB Modules

when calling TMDBAPIService from TMDB_Shared_Backend, remember to use `typealias` to 

| Module | Architecture | Reactive Model |
|--------|-------------|----------------|
| TMDB_Discover | Clean Architecture | Combine   |
| TMDB_Feed | MVVM | Combine   |
| TMDB_Profile | Clean Architecture | Combine   |
| TMDB_MovieDetail | MVVM | Combine   |
| TMDB_TVShowDetail | Data Store pattern | Combine   |

### Pokedex Modules

| Module | Architecture | Reactive Model |
|--------|-------------|----------------|
| Pokedex_Pokelist | VIPER | Traditional delegate pattern |
| Pokedex_Detail | MVVM | RxSwift (BehaviorRelay, PublishRelay) |

### Shared Modules

| Module | Architecture | Reactive Model |
|--------|-------------|----------------|
| TMDB_Shared_Backend | Service layer pattern | Combine for authentication state |
| TMDB_Shared_UI | Component-based architecture | SwiftUI native reactive |

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