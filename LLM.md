Refer to me as Mr. Client.

List all the skills and MCP you're planing to use before starting and what you used after completing a response.
Do not put yourself as co-author.
When you finish a response with code changes, add a one-liner of summary so I can use as commit message.

## Build Commands
When building for testing, use the Xcode build script instead of `swift build`, replace `EverythingClient` with the target I'm currently working on:
```bash
scheme=EverythingClient bash .github/scripts/build.sh
```

For macOS, build the app scheme (the `EverythingClient` scheme's test plan is iOS-only):
```bash
scheme=Rebuild platform=macOS action=build bash .github/scripts/build.sh
```

## Project Structure
- This is an iOS + macOS project using Xcode workspace, feature based modularization
- Each module has a different architecture (such as MVVM, Clean architecture, ...)
- Main scheme: EverythingClient

## Development Guidelines
- when working on a module, look at the structure of the module to see if whether it is mainly SwiftUI or RxSwift or UIKit, and what the architecture is (MVVM, Clean, ...) before start writing code
- look at root level **Package.swift** first to know the dependencies before start implementation
- some modules are iOS-only (TMDB_Discover, TMDB_Profile, Pokedex_Pokelist, Pokedex_Detail, third_party, Shared_UI_Support_UIKit). See "Platforms" in README.md before adding code that crosses those boundaries; use the shims in `Sources/CoreFeatures/Platform/` rather than `#if os(iOS)` at call sites