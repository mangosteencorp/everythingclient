@.agents/feature-build-guide.md
@.agents/git-commit.md
Refer to me as Mr. Client.

If I put numbering on every tasks, spawn an agent for each task. wait for each to report back before continue

Every time you start a session, make sure to ask me before making any file change
- if I allow you to git commit & git push (refer to agent .agents/git-commit.md if I allow you to)
- list me all the modules you're planning to fix and I'll confirm which one I allow you to make changes

## How you'll work

List all the skills and MCP you're planing to use before starting and what you used after completing a response.
Do not put yourself as co-author.
When you finish a response with code changes, add a one-liner of summary so I can use as commit message.

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
- use agent .agents/feature-build-guide.md to work on feature development
- Stop at every step and commit if the work is multiple features (use .agents/git-commit.md)

## Style

Follow YAGNI principles, and prefer one-liner solutions

## Structures
- at the end of the response, list out the Apple APIs or external APIs you used

## Vendored code
- `ThirdParty/BrowserKit` is a copy of Firefox for iOS's BrowserKit trimmed to `Redux` (+ `Common`, which it needs). Don't edit it; read `ThirdParty/BROWSERKIT_SYNC.md` before touching or updating it.
