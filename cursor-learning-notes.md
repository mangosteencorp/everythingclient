# Claude Learning Notes

## Industry Practices Used

**iOS Version Compatibility Management**: Used `@available(iOS X, *)` annotations to handle different iOS version requirements across modules. This is a common practice in iOS development to maintain backward compatibility while leveraging newer APIs.

**Modular Architecture**: Implemented feature-based modularization where each module has different architecture patterns (MVVM, Clean Architecture, etc.). This follows industry best practices for large-scale iOS applications.

**Public Access Control**: Used `public` access modifiers extensively for cross-module communication, which is essential in modular Swift projects.

**Availability Checking**: Used `#available(iOS X, *)` runtime checks to conditionally execute code based on iOS version, ensuring graceful degradation.

**Conditional Compilation**: Used `#if DEBUG` to wrap demo views so they won't be shipped to TestFlight, following iOS development best practices.

**Module Separation**: Created demo views in their respective modules (TMDB_Feed, Shared_UI_Support) rather than duplicating them in Integration_test, promoting code reuse and maintainability.

## Apple & 3rd Party APIs Used

**SwiftUI**: Used for modern iOS UI development with `@available` annotations for iOS version compatibility.

**Xcode Build System**: Used `xcodebuild` with workspace and scheme management for modular builds.

**iOS Simulator Management**: Used `xcrun simctl` for device management and testing.

**Package Manager**: Used Swift Package Manager for dependency management across modules.

## Current Issues & Solutions

**DemoTests Scheme Issue**: The DemoTests scheme in the Rebuild project can't access Integration_test module due to missing Package.swift configuration. This requires updating the Rebuild project's Package.swift to include the main workspace modules.

**Signing Issues**: DemoTests scheme has signing configuration issues that prevent building without proper development team setup.

## Next Steps

1. Update Rebuild/Package.swift to include Integration_test and other required modules
2. Configure proper signing for DemoTests scheme
3. Test all demo views in Integration_test module 