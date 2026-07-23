iOS Best Practices Demo Project
=============================

This repository serves its purpose as  comprehensive iOS project demonstrating current best practices and modern iOS development approaches. It tries to replicate as many best practices as possible across mulitple iOS architectures and free public APIs. Testflight: https://testflight.apple.com/join/FaXX2mUY

<details>
<summary>How to enable Pokedex on TestFlight version</summary>

Please search for a Pokemon film and click on "Pocket Monster" keyword from detail page to enable Pokedex tab.

</details>

<details>
<summary>Getting started</summary>
Create a xcconfig file with this pattern in Build.xcconfig:

```
TMDB_API_KEY=
PRODUCT_BUNDLE_IDENTIFIER=
```

Also adding a GoogleService-Info.plist file to the root of the project for Firebase Analytics. (Or setting the false flag in Rebuild/Rebuild/RebuildApp.swift to skip Firebase Analytics)

</details>


- [iOS Best Practices Demo Project](#ios-best-practices-demo-project)
- [Overview](#overview)
  - [Screenshots](#screenshots)
    - [Special Features](#special-features)
    - [Screens](#screens)
      - [TMDB](#tmdb)
      - [Pokedex](#pokedex)
    - [Design inspirations](#design-inspirations)
      - [Small projects](#small-projects)
      - [Commercial apps](#commercial-apps)
      - [Large open source apps](#large-open-source-apps)
- [Best Practices](#best-practices)
  - [Security](#security)
  - [Testing](#testing)
  - [Development Tools, Build tools \& Automation](#development-tools-build-tools--automation)
  - [UI/UX](#uiux)
    - [Multiple themes](#multiple-themes)
  - [Other app features](#other-app-features)
- [Project Structure](#project-structure)
  - [CI/CD](#cicd)
  - [Collaboration](#collaboration)
  - [Architecture \& Design](#architecture--design)
    - [Navigation](#navigation)
      - [TMDB Navigation Matrix](#tmdb-navigation-matrix)
    - [Feature based Modularization:](#feature-based-modularization)
      - [Module Architecture Overview](#module-architecture-overview)
      - [Module Architecture Layers](#module-architecture-layers)


# Overview 

What you'll find looking at this repo:
- feature based modularization with Swift packages
- VIPER, Clean & MVVM, SwiftUI & UIKit
- REST API & GraphQL networking & OAuth 
- SwiftGen, SwiftLint, SwiftFormat
- GitHub CI build & test

## Screenshots

### Special Features

<div style="overflow-x: auto; white-space: nowrap; -webkit-overflow-scrolling: touch;">
  <table>
    <thead>
      <tr>
        <th>Design Switching</th>
        <th>Theme Switching</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td><img src=".screenshots/switch-design.gif" alt="Design Switch" width="200"/></td>
        <td><img src=".screenshots/switch-themes.gif" alt="Theme Switch" width="200"/></td>
      </tr>
    </tbody>
  </table>
</div>

### Screens
#### TMDB

<div style="overflow-x: auto; white-space: nowrap; -webkit-overflow-scrolling: touch;">
  <table style="width: auto; table-layout: auto;">
    <thead>
      <tr>
        <th>TMDB</th>
        <th>Movie List</th>
        <th>TV list</th>
        <th>search & filters</th>
        <th>Movie Detail</th>
        <th>TV Detail</th>
        <th>Profile</th>
        <th>endless loading</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td></td>
        <td style="width: 200px;"><img src=".screenshots/moviefeed.gif" alt="Movie Feed" width="200" style="max-width: none;"/></td>
        <td style="width: 300px;"><img src=".screenshots/tvfeed.png" alt="TV Feed" width="300" style="max-width: none;"/></td>
        <td style="width: 200px;"><img src=".screenshots/search-filter.gif" alt="Search & Filters" width="200" style="max-width: none;"/></td>
        <td style="width: 200px;"><img src=".screenshots/movie-detail.gif" alt="TV Detail" width="200" style="max-width: none;"/></td>
        <td style="width: 200px;"><img src=".screenshots/tv-detail.gif" alt="TV Detail" width="200" style="max-width: none;"/></td>
        <td style="width: 200px;"><img src=".screenshots/profile-page.gif" alt="Profile" width="200" style="max-width: none;"/></td>
        <td style="width: 200px;"><img src=".screenshots/moviefeed-endless.gif" alt="Endless Loading" width="200" style="max-width: none;"/></td>
      </tr>
    </tbody>
  </table>
</div>

#### Pokedex

<div style="overflow-x: auto; white-space: nowrap; -webkit-overflow-scrolling: touch; margin-top: 20px;">
  <table>
    <thead>
      <tr>
        <th>Pokedex</th>
        <th>Poke list</th>
        <th>Pokemon detail</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td></td>
        <td><img src=".screenshots/pokemon-list.png" alt="Pokemon List" width="200"/></td>
        <td><img src=".screenshots/pokemon-detail.png" alt="Pokemon Detail" width="200"/></td>
      </tr>
    </tbody>
  </table>
</div>

### Design inspirations
#### Small projects

#### Commercial apps

<table>
  <tr>
    <th>Screen name</th>
    <th>Home screen</th>
  </tr>
  <tr>
    <td><img src="https://private-user-images.githubusercontent.com/43954417/521134031-17055c00-f65a-4c21-9ecb-587a12f89801.jpeg?jwt=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3NjQ2NTIzNTUsIm5iZiI6MTc2NDY1MjA1NSwicGF0aCI6Ii80Mzk1NDQxNy81MjExMzQwMzEtMTcwNTVjMDAtZjY1YS00YzIxLTllY2ItNTg3YTEyZjg5ODAxLmpwZWc_WC1BbXotQWxnb3JpdGhtPUFXUzQtSE1BQy1TSEEyNTYmWC1BbXotQ3JlZGVudGlhbD1BS0lBVkNPRFlMU0E1M1BRSzRaQSUyRjIwMjUxMjAyJTJGdXMtZWFzdC0xJTJGczMlMkZhd3M0X3JlcXVlc3QmWC1BbXotRGF0ZT0yMDI1MTIwMlQwNTA3MzVaJlgtQW16LUV4cGlyZXM9MzAwJlgtQW16LVNpZ25hdHVyZT1kNjA2OWE4MDU0YzFjZjk4MTZjMjA0NzdjNWMxMzQ1MmIwMzE0ZTY1OWRiOGUwMzFmYzYzY2M0NDMzMTNkZTIyJlgtQW16LVNpZ25lZEhlYWRlcnM9aG9zdCJ9.MZjc3BKfWu7bHnf5U3bqiMKNSU99bs3BAptjZpdcp1Q"></td>
    <td style="padding: 80px 120px;"><img src=".screenshots/discover-page.gif" style="transform: rotate(90deg);"></td>
  </tr>
  <tr>
    <td>Reference</td>
    <td>My TMDB_Discover module</td>
  </tr>
  
</table>

#### Large open source apps

# Best Practices

## Security

- Secure Credential Management
    - ✅ API keys stored in GitHub Secrets for CI/CD and read when running workflows (see .github/workflows/ci.yml)
    - ✅ Sensitive tokens (`session_id` here) stored in iOS Keychain after authentication (see TMDB_Shared_Backend module)

## Testing

🚧 Testing: 
- ✅ 100% code coverage for TMDB_Discover module. For testabbility purpose:
    - Data layer & domain layer should be wrapped in protocol for easy mocking. Mocking `URLProtocol` is for testing URLSession Task creation.
    - Using ViewInspector library for SwiftUI unit testing.

## Development Tools, Build tools & Automation

- ✅ Code Generation
    - 🔴 Sourcery for mock generation
    - ✅ SwiftGen for type-safe assets and localizations (Note: SwiftGen still not supporting Xcode 15 String catalog so this project still use .strings files.)
    - 
- ✅ Linting & Formatting: run `swiftformat .` or `swift package plugin swiftlint` at project root level
  - SwiftFormat and SwiftLint are also run as "run script phase" in Xcode build settings.
  - ✅ SwiftLint is also run as a GitHub Action workflow, Linting on every pull request. (SwiftLint doesn't work well with `// swiftlint:disable` comments on Ubuntu)

</details>

## UI/UX

- 🚧 UI Development
    - ✅ SwiftUI Previews for all UI components, including `UIView` and `UIViewController`, 
        - 🚧 Preview should be covering all states from view models.
    - 🚧 Demo implementations for all UI modules

### Multiple themes

- ✅ Support multiple themes:
    - ✅ Light theme
    - ✅ Dark theme
    - ✅ Sepia theme
    - ✅ System theme

## Other app features

Tracking:
- ✅  Using Firebase Analytics for tracking events with abstraction to avoid direct dependency of each module.
  - GoogleService-Info.plist is ignored by Git and should be set as a secret in GitHub.

# Project Structure
## CI/CD

Using GitHub Actions for CI/CD.
- ✅ ios.yml and test.sh files can generate coverage report for modules with tests. 3 actions workflow:
  - SwiftLint run
  - Build project
  - Test pre-defined schemes on available simulators
- 🔴 upload to TestFlight (or BrowserStack, Remote Testkit, etc.)

## Collaboration

Setup on GitHub for team collaboration:
- ✅ automatically running unit tests and code coverage on newly opened pull requests. (Due to SwiftPM limitation mentioned above, test.sh using a custom command of `xcrun llvm-cov` instead of a normal xctestplan file) 
- 🚧 Block merging pull requests unless certain conditions are met (e.g. code coverage is 100%, 2 approvals from other team members, etc.)


Progress status is classified as: ✅ Finished 🚧 In Progress 🔴 Not Started 🔔 Finished but needs updates


## Architecture & Design


### Navigation

Using Router Pattern, `NavigationStack` and Coordinator pattern

#### TMDB Navigation Matrix

The TMDB section uses a Coordinator pattern with NavigationStack for routing between screens. Below is a comprehensive matrix showing navigation capabilities:

**Tab Routes (Root Level)**
- Movie Feed (`movieFeed`)
- Marketplace/Discover (`marketplace`)
- Profile (`profile`)

**Navigation Destinations**

| From Screen | To Screen | Route Type | Status | Notes |
|------------|-----------|------------|--------|-------|
| **Movie Feed** | Movie Detail | `TMDBRoute.movieDetail` | ✅ | Tap on movie in feed |
| **Movie Feed** | TV Show Detail | `TMDBRoute.tvShowDetail` | ✅ | Tap on TV show in feed |
| **Movie Feed** | Movie List (Filtered) | `TMDBRoute.movieList` | ✅ | Apply filters/search |
| **Marketplace/Discover** | Movie Detail | `TMDBRoute.movieDetail` | ✅ | Tap on trending movie |
| **Marketplace/Discover** | TV Show Detail | `TMDBRoute.tvShowDetail` | ✅ | Tap on trending TV show |
| **Marketplace/Discover** | TV Show List | `TMDBRoute.tvShowList` | ✅ | Tap genre/cast/on-the-air |
| **Profile** | Movie Detail | `TMDBRoute.movieDetail` | ✅ | Tap favorite/watchlist movie |
| **Profile** | TV Show Detail | `TMDBRoute.tvShowDetail` | ✅ | Tap favorite/watchlist TV show |
| **Movie Detail** | Movie List (by Keyword) | `TMDBRoute.movieList(.keyword)` | ✅ | Tap keyword tag |
| **Movie Detail** | Cast/Crew Detail | 🔴 | Not implemented | No route for person detail |
| **TV Show Detail** | Season Detail | 🔴 | Not implemented | Internal to TVShowDetail |
| **TV Show Detail** | Cast Detail | 🔴 | Not implemented | No route for person detail |
| **TV Show List** | TV Show Detail | `TMDBRoute.tvShowDetail` | ✅ | Tap TV show in filtered list |
| **Movie List** | Movie Detail | `TMDBRoute.movieDetail` | ✅ | Tap movie in filtered list |
| **Any Screen** | Person/Cast Detail | 🔴 | Missing | Would need `TMDBRoute.personDetail` |

**Navigation Parameters**

1. **`TMDBRoute.movieDetail(MovieRouteModel)`**
   - Required: movie ID
   - Optional: title, overview, poster path, backdrop path, vote average, etc.

2. **`TMDBRoute.tvShowDetail(Int)`**
   - Required: TV show ID

3. **`TMDBRoute.movieList(AdditionalMovieListParams)`**
   - Supports: keyword filtering, genre filtering, cast filtering
   - Example: `.movieList(.keyword(123))`

4. **`TMDBRoute.tvShowList(TVShowFeedType)`**
   - Supports: `.onTheAir`, `.discoverWithGenre`, `.discoverWithTVGenre`, `.discoverWithCast`

**Missing Navigation Routes**
- 🔴 Person/Cast Detail page (tap on actor/crew member)
- 🔴 Season Detail page (separate from TV show detail)
- 🔴 Episode Detail page
- 🔴 Reviews/Comments page
- 🔴 Similar Movies/TV Shows (currently might be handled via movieList/tvShowList)

### Feature based Modularization:

✅ Using Swift Package Manager to manage dependencies and only leaving a thin app shell using Xcode project. This is way more Git friendly than using Xcode project. However, it's still debatable if this is better than using new XC16 buildable folders (Package.swift at root level is also difficult to setup on latest Xcode version.). 
    - Pros: Swift, readable & Git friendly 
    - Cons: code suggestions, previews not as smooth as using Xcode project, coverage report also not ignoring test files.

Swinject are used for dependency injection.

#### Module Architecture Overview

Quick reference for each Swift package module — UI stack, reactive layer, architecture pattern, and test coverage.

**Patterns at a glance**

| Pattern | Modules |
|---------|---------|
| MVVM | `TMDB_Feed`, `TMDB_MovieDetail`, `Pokedex_Detail` |
| Clean Architecture | `TMDB_Discover`, `TMDB_Profile` |
| VIPER | `Pokedex_Pokelist` |
| Coordinator / Router | `TMDB`, `Pokedex` |
| Data Store (inline `@Observable`/`Store`) | `TMDB_TVShowDetail`, `TMDB_Person` |
| Shared / no UI pattern | `TMDB_Shared_Backend`, `Pokedex_Shared_Backend`, `CoreFeatures`, `Shared_UI_Support` |

**App shell**

- **everythingclient**: SwiftUI + Combine — app shell — tests: 🔴 (placeholder only)
- **TMDB**: SwiftUI + Combine — Coordinator — tests: 🔴
- **Integration_test**: SwiftUI — demo launcher (not a production feature) — tests: n/a

**TMDB feature modules**

- **TMDB_Feed**: SwiftUI + Combine + async/await — MVVM — tests: ✅
- **TMDB_Discover**: SwiftUI + UIKit (mixed) + async/await — Clean Architecture — tests: ✅
- **TMDB_MovieDetail**: SwiftUI + Combine + async/await — MVVM — tests: 🔴
- **TMDB_TVShowDetail**: SwiftUI + async/await — Data Store — tests: 🔴
- **TMDB_Person**: SwiftUI + async/await — Data Store — tests: 🔴
- **TMDB_Profile**: UIKit + RxSwift (+ Combine for auth) — Clean Architecture — tests: 🔴
- **PhotoListViewer**: SwiftUI — simple view module — tests: 🔴

**Pokedex feature modules**

- **Pokedex**: SwiftUI + UIKit bridge — Coordinator / Router — tests: 🔴
- **Pokedex_Pokelist**: UIKit + async/await — VIPER — tests: 🔴
- **Pokedex_Detail**: UIKit + RxSwift/RxCocoa — MVVM — tests: 🔴

**Shared / infrastructure modules**

- **TMDB_Shared_Backend**: no UI — Combine + async/await, light Clean (repository layer) — tests: ✅
- **TMDB_Shared_UI**: SwiftUI + Combine — shared UI components — tests: 🔴
- **Pokedex_Shared_Backend**: no UI — async/await + Apollo GraphQL — tests: 🔴
- **CoreFeatures**: SwiftUI + UIKit — theming & analytics abstractions — tests: 🔴
- **Shared_UI_Support**: SwiftUI + UIKit — cross-feature UI helpers — tests: 🔴

**Gaps to fill** (patterns or coverage not yet represented):

- 🔴 VIPER with RxSwift (Pokedex list uses async/await instead)
- 🔴 UIKit + Combine feature module (Profile uses RxSwift; Discover home is UIKit but driven by Clean Architecture)
- 🔴 Clean Architecture + SwiftUI-only (Discover mixes UIKit; Profile is UIKit)
- 🔴 Tests for most feature modules except `TMDB_Feed`, `TMDB_Discover`, and `TMDB_Shared_Backend`
- 🔴 Person detail navigation from movie/TV screens (see [Navigation Matrix](#tmdb-navigation-matrix))

#### Module Architecture Layers

Below are the folder structures showing the architectural layers for each module:

**Pokedex** (Coordinator Pattern)
```
Pokedex/
├── PokedexView.swift
└── Router/
    └── PokelistRouter.swift
```

**Pokedex_Detail** (MVVM)
```
Pokedex_Detail/
├── View/
│   ├── PokemonDetailViewController.swift
│   ├── PokemonContentDetailViewController.swift
│   └── LoadingViewController.swift
└── ViewModel/
    └── PokemonDetailViewModel.swift
```

**Pokedex_Pokelist** (VIPER)
```
Pokedex_Pokelist/
├── Entities/
│   └── PokemonEntity.swift
├── Interactor/
│   └── PokelistInteractor.swift
├── Presenter/
│   └── PokelistPresenter.swift
├── View/
│   ├── PokelistViewController.swift
│   └── PokemonCell.swift
└── Protocols/
    └── PokelistProtocols.swift
```

**TMDB_Discover** (Clean Architecture)
```
TMDB_Discover/
├── app/ (DI)
│   └── DiscoverAssembly.swift
├── data/
│   ├── datasource/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecase/
└── presentation/
    ├── pages/
    ├── view_models/
    └── widgets/
```

**TMDB_Feed** (MVVM)
```
TMDB_Feed/
├── Backend/
│   └── APIServiceProtocol.swift
├── Model/
│   ├── MovieModel.swift
│   └── MovieListResponse.swift
├── ViewModels/
│   ├── MovieFeedViewModel.swift
│   └── TVShowFeedViewModel.swift
└── Views/
    ├── Pages/
    └── Widgets/
```

**TMDB_MovieDetail** (MVVM)
```
TMDB_MovieDetail/
├── Model/
│   ├── Movie.swift
│   ├── People.swift
│   └── Genre.swift
├── ViewModels/
│   ├── MovieDetailViewModel.swift
│   ├── MovieCastingViewModel.swift
│   └── MovieWatchProvidersViewModel.swift
└── Views/
    ├── Pages/
    ├── Sections/
    └── StaticViews/
```

**TMDB_Profile** (Clean Architecture)
```
TMDB_Profile/
├── DI/
│   └── ProfileAssembly.swift
├── Data/
│   └── Repositories/
├── Domain/
│   ├── Entities/
│   ├── Repositories/
│   └── UseCases/
└── Presentation/
    ├── controllers/
    ├── ViewModels/
    └── Views/
```

**TMDB_TVShowDetail** (Data Store Pattern - SwiftUI)
```
TMDB_TVShowDetail/
├── Views/
│   ├── TVShowDetailView.swift
│   ├── TVShowDetailContentView.swift
│   └── (Component views)
└── Resources/
```

