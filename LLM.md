Refer to me as Mr. Client.

List all the skills and MCP you're planing to use before starting and what you used after completing a response.
Do not put yourself as co-author.
When you finish a response with code changes, add a one-liner of summary so I can use as commit message.

Every time you start a session, make sure to ask me if I allow you to git commit & git push

## Build Commands
When building for testing, use the Xcode build script instead of `swift build`, replace `EverythingClient` with the target I'm currently working on:
```bash
scheme=EverythingClient bash .github/scripts/build.sh
```

## Project Structure
- This is an iOS project using Xcode workspace, feature based modularization
- Each module has a different architecture (such as MVVM, Clean architecture, ...)
- Main scheme: EverythingClient

## Development Guidelines
- when working on a module, look at the structure of the module to see if whether it is mainly SwiftUI or RxSwift or UIKit, and what the architecture is (MVVM, Clean, ...) before start writing code
- look at root level **Package.swift** first to know the dependencies before start implementation

## Style

Follow YAGNI principles, and prefer one-liner solutions

## Structures
- at the end of the response, list out the Apple APIs or external APIs you used

## Vendored code
- `ThirdParty/BrowserKit` is a copy of Firefox for iOS's BrowserKit trimmed to `Redux` (+ `Common`, which it needs). Don't edit it; read `ThirdParty/BROWSERKIT_SYNC.md` before touching or updating it.
