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
- [Practices](#practices)
  - [Architecture \& Design](#architecture--design)
    - [Feature based Modularization:](#feature-based-modularization)
    - [Navigation](#navigation)
  - [Security](#security)
  - [Testing](#testing)
  - [Development Tools, Build tools \& Automation](#development-tools-build-tools--automation)
  - [UI/UX](#uiux)
    - [Multiple themes](#multiple-themes)
  - [Other app features](#other-app-features)
- [Project Structure](#project-structure)
  - [CI/CD](#cicd)
  - [Collaboration](#collaboration)


# Overview 

What you'll find looking at this repo:
- feature based modularization with Swift packages
- VIPER, Clean & MVVM, SwiftUI & UIKit
- REST API & GraphQL networking & OAuth 
- SwiftGen, SwiftLint, SwiftFormat
- GitHub CI build & test

# Practices

## Architecture & Design

### Feature based Modularization:

✅ Using Swift Package Manager to manage dependencies and only leaving a thin app shell using Xcode project. This is way more Git friendly than using Xcode project. However, it's still debatable if this is better than using new XC16 buildable folders (Package.swift at root level is also difficult to setup on latest Xcode version.). 
    - Pros: Swift, readable & Git friendly 
    - Cons: code suggestions, previews not as smooth as using Xcode project, coverage report also not ignoring test files.

Swinject are used for dependency injection.

Details of packages:
- **TMDB_MVVM_Detail**: Showing details of a movie including overview, cast, crew, keywords, etc. Using **SwiftUI** and **MVVM architecture**. 
- **TMDB_Clean_MLS**: Display list of TV shows (from "up in the air" or "airing today" TMDB API) using **Clean Architecture** and **SwiftUI**.
- **TMDB_MVVM_MLS**: same as TMDB_Clean_MLS but using **MVVM architecture**. Also supports endless loading
- **TMDB_Clean_Profile**: Handling authentication and displaying user profile (including avatar, favourite movies & TV shows & watchlist). Using **Clean Architecture** and **UIKit** and **Combine** for concurrency.
- **TMDB_TVShowDetail**: Showing details of a TV show including overview, cast, crew, TV seasons. Using **SwiftUI** and Data Store pattern. **Support multiple themes**.
- **Pokedex_Pokelist**: loading a Pokemon list from Pokedex **GraphQL** API. Using **VIPER** architecture and **UIKit**
- **Pokedex_Detail**: loading a Pokemon detail from Pokedex **GraphQL** API. Using RxSwift & RxCocoa for reactive programming. MVVM architecture.

### Navigation

Using Router Pattern, `NavigationStack` and Coordinator pattern

## Security

- Secure Credential Management
    - ✅ API keys stored in GitHub Secrets for CI/CD and read when running workflows (see .github/workflows/ci.yml)
    - ✅ Sensitive tokens (`session_id` here) stored in iOS Keychain after authentication (see TMDB_Shared_Backend module)

## Testing

🚧 Testing: 
- ✅ 100% code coverage for TMDB_TVFeed module. For testabbility purpose:
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