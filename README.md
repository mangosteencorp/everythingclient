iOS Best Practices Demo Project
=============================

A comprehensive iOS project demonstrating current best practices and modern iOS development approaches.

Legend:
- ✅ Finished
- 🚧 In Progress
- 🔴 Not Started
- 🔔 Finished but needs updates

# Project Structure

## Architecture & Design

Modular Architecture
- ✅ All Swift code organized in a more Git friendly Swift packages, only leaving a thin app shell using Xcode project
  - **Note**: structuring Package.swift at root level might not be possible on latest Xcode versions.
- [ ] Feature-per-target approach: each feature has its own target: We can go as further as one screen per target.
- [ ] Router pattern for inter-module navigation
    

## Security

- Secure Credential Management
    - ✅ API keys stored in GitHub Secrets for CI/CD
    - 🚧 Sensitive tokens stored in iOS Keychain

## Backend Integration

- 🚧 Multiple API Integration Examples
    - 🚧 REST API implementation (TMDB)
    - 🔴 GraphQL implementation (Rick & Morty API)

## Development Tools & Automation

- ✅ Code Generation
    - 🔴 Sourcery for mock generation
    - 🚧 SwiftGen for type-safe assets and localizations (Note: SwiftGen still not supporting Xcode 15 String catalog)

- 🚧 CI/CD Pipeline
    - GitHub Workflows:
        - 🚧Automated testing on PR
        - 🚧 Code coverage checks
        - Auto-deployment to TestFlight
        - Auto-deployment to BrowserStack
        - Scheduled integration testing
        - Automated snapshot testing

## UI/UX

- 🚧 UI Development
    - [ ] SwiftUI Previews for all UI components
    - [ ] Demo implementations for all UI targets
    - [ ] Snapshot tests for UI consistency


# Architecture Content Overview

Featuring:
- MVVM + SwiftUI
- Clean Architecture + SwiftUI

In progress:
- UIKit + Clean Architecture


# Backend Integration

The project showcases different backend integration approaches:

1. **REST API (TMDB)**
   - [Description of implementation]

2. **GraphQL (Rick & Morty)**
   - [Description of implementation]

# Development Workflow

## CI/CD Pipeline

Automated workflows include:
- 🚧 Pull Request validation
- 🚧 Test coverage reporting
- 🚧 Automated deployments
- 🚧 Integration testing
- 🚧 UI testing
