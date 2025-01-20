iOS Best Practices Demo Project
=============================

This repository serves its purpose as  comprehensive iOS project demonstrating current best practices and modern iOS development approaches. It tries to replicate as many best practices as possible across mulitple iOS architectures and free public APIs.

Progress status is classified as:
- ✅ Finished
- 🚧 In Progress
- 🔴 Not Started
- 🔔 Finished but needs updates

# Overview 

Clear separation of features into modules: There's 4 feature modules in this project to displaying content from TMDB REST API:
- **TMDB_MVVM_Detail**: Showing details of a movie including overview, cast, crew, keywords, etc. Using **SwiftUI** and **MVVM architecture**. 
- **TMDB_Clean_MLS**: Display list of movies (from now playing or popular TMDB API) using **Clean Architecture** and **SwiftUI**.
- **TMDB_MVVM_MLS**: same as TMDB_Clean_MLS but using **MVVM architecture**. Also supports endless loading
- **TMDB_Clean_Profile**: Handling authentication and displaying user profile (including avatar, favourite movies & TV shows & watchlist). Using **Clean Architecture** and **UIKit** and **Combine** for concurrency.
- **Pokedex_Pokelist**: loading a Pokemon list from Pokedex **GraphQL** API. Using **VIPER** architecture and **UIKit**

These modules are connected using Coordinator pattern.


<details>
<summary>Getting started</summary>
Create a xcconfig file with this pattern:
```
TMDB_API_KEY=1d9b898a212ea52e283351e521e17871
PRODUCT_BUNDLE_IDENTIFIER=com.openmangosteen.everythingclient
```
</details>

# Practices

## Architecture & Design

Modularization:
- ✅ Using Swift Package Manager to manage dependencies and only leaving a thin app shell using Xcode project. This is way more Git friendly than using Xcode project. However, it's still debatable if this is better than using new XC16 buildable folders (Package.swift at root level is also difficult to setup on latest Xcode version.). 
    - Pros: Swift, readable & Git friendly 
    - Cons: code suggestions, previews not as smooth as using Xcode project, coverage report also not ignoring test files.

Swinject are used for dependency injection.

## Security

- Secure Credential Management
    - ✅ API keys stored in GitHub Secrets for CI/CD and read when running workflows (see .github/workflows/ci.yml)
    - ✅ Sensitive tokens (`session_id` here) stored in iOS Keychain after authentication (see TMDB_Shared_Backend module)

## Testing

🚧 Testing: 
- ✅ 100% code coverage for TMDB_Clean_MLS module. For testabbility purpose:
    - Data layer & domain layer should be wrapped in protocol for easy mocking. Mocking `URLProtocol` is for testing URLSession Task creation.
    - Using ViewInspector library for SwiftUI unit testing.
- 🔴 Snapshot testing using PointFreeCo's SnapshotTesting library
- 🔴 UI testing for integration tests

## Development Tools & Automation

- ✅ Code Generation
    - 🔴 Sourcery for mock generation
    - ✅ SwiftGen for type-safe assets and localizations (Note: SwiftGen still not supporting Xcode 15 String catalog so this project still use .strings files.)

## UI/UX

- 🚧 UI Development
    - ✅ SwiftUI Previews for all UI components, including `UIView` and `UIViewController`, 
        - 🚧 Preview should be covering all states from view models.
    - 🚧 Demo implementations for all UI modules


# Project Structure
## CI/CD

Using GitHub Actions for CI/CD.
- ✅ ios.yml and test.sh files can generate coverage report for modules with tests. 
- 🔴 upload to TestFlight (or BrowserStack, Remote Testkit, etc.)

## Collaboration

Setup on GitHub for team collaboration:
- ✅ automatically running unit tests and code coverage on newly opened pull requests. (Due to SwiftPM limitation mentioned above, test.sh using a custom command of `xcrun llvm-cov` instead of a normal xctestplan file) 
- 🔴 Block merging pull requests unless certain conditions are met (e.g. code coverage is 100%, 2 approvals from other team members, etc.)
