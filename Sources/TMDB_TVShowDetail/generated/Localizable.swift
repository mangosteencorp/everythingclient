import Foundation

@available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
extension LocalizedStringResource {
    /// Constant values for the Localizable Strings Catalog
    ///
    /// ```swift
    /// // Accessing the localized value directly
    /// let value = String(localized: .localizable.createdBy)
    /// value // "Created by"
    ///
    /// // Working with SwiftUI
    /// Text(.localizable.createdBy)
    /// ```
    internal struct Localizable {

        internal func averageVote(_ arg1: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "average.vote",
                defaultValue: ###"Average vote: \###(arg1)"###,
                table: "Localizable",
                bundle: .current
            )
        }

        internal var createdBy: LocalizedStringResource {
            LocalizedStringResource(
                "created.by",
                defaultValue: ###"Created by"###,
                table: "Localizable",
                bundle: .current
            )
        }

        internal var details: LocalizedStringResource {
            LocalizedStringResource(
                "details",
                defaultValue: ###"Details"###,
                table: "Localizable",
                bundle: .current
            )
        }

        internal func error(_ arg1: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "error",
                defaultValue: ###"Error: \###(arg1)"###,
                table: "Localizable",
                bundle: .current
            )
        }

        internal func firstAirDate(_ arg1: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "first.air.date",
                defaultValue: ###"First air date: \###(arg1)"###,
                table: "Localizable",
                bundle: .current
            )
        }

        internal var genres: LocalizedStringResource {
            LocalizedStringResource(
                "genres",
                defaultValue: ###"Genres"###,
                table: "Localizable",
                bundle: .current
            )
        }

        internal func lastAirDate(_ arg1: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "last.air.date",
                defaultValue: ###"Last air date: \###(arg1)"###,
                table: "Localizable",
                bundle: .current
            )
        }

        internal var loadingTvShowDetails: LocalizedStringResource {
            LocalizedStringResource(
                "loading.tv.show.details",
                defaultValue: ###"Loading TV Show Details..."###,
                table: "Localizable",
                bundle: .current
            )
        }

        internal func numberOfEpisodes(_ arg1: Int) -> LocalizedStringResource {
            LocalizedStringResource(
                "number.of.episodes",
                defaultValue: ###"Number of episodes: \###(arg1)"###,
                table: "Localizable",
                bundle: .current
            )
        }

        internal func numberOfSeasons(_ arg1: Int) -> LocalizedStringResource {
            LocalizedStringResource(
                "number.of.seasons",
                defaultValue: ###"Number of seasons: \###(arg1)"###,
                table: "Localizable",
                bundle: .current
            )
        }

        internal var overview: LocalizedStringResource {
            LocalizedStringResource(
                "overview",
                defaultValue: ###"Overview"###,
                table: "Localizable",
                bundle: .current
            )
        }

        internal func seasonAirDate(_ arg1: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "season.air.date",
                defaultValue: ###"Air date: \###(arg1)"###,
                table: "Localizable",
                bundle: .current
            )
        }

        internal func seasonEpisodeCount(_ arg1: Int) -> LocalizedStringResource {
            LocalizedStringResource(
                "season.episode.count",
                defaultValue: ###"\###(arg1) episodes"###,
                table: "Localizable",
                bundle: .current
            )
        }

        internal var seasons: LocalizedStringResource {
            LocalizedStringResource(
                "seasons",
                defaultValue: ###"Seasons"###,
                table: "Localizable",
                bundle: .current
            )
        }

        internal func status(_ arg1: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "status",
                defaultValue: ###"Status: \###(arg1)"###,
                table: "Localizable",
                bundle: .current
            )
        }
    }

    /// Constant values for the Localizable Strings Catalog
    ///
    /// ```swift
    /// // Accessing the localized value directly
    /// let value = String(localized: .localizable.createdBy)
    /// value // "Created by"
    ///
    /// // Working with SwiftUI
    /// Text(.localizable.createdBy)
    /// ```
    internal static let localizable = Localizable()
}

@available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
private extension LocalizedStringResource.BundleDescription {
    #if !SWIFT_PACKAGE
    private class BundleLocator {
    }
    #endif

    static var current: Self {
        #if SWIFT_PACKAGE
        .atURL(Bundle.module.bundleURL)
        #else
        .forClass(BundleLocator.self)
        #endif
    }
}