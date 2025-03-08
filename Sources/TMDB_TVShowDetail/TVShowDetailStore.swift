//
//  TVShowDetailState.swift
//  everythingclient
//
//  Created by Quang on 2025-03-07.
//

import Foundation
import SwiftUI
import TMDB_Shared_Backend

// Define possible states for the TV show detail view
public enum TVShowDetailState {
    case loading
    case loaded(TVShowDetailModel)
    case error(Error)
}

// The DataStore for TV show details
public class TVShowDetailStore: ObservableObject {
    @Published public private(set) var state: TVShowDetailState = .loading
    private let apiService: TMDBAPIService
    private let tvShowId: Int

    public init(apiService: TMDBAPIService, tvShowId: Int) {
        self.apiService = apiService
        self.tvShowId = tvShowId
    }

    // Fetch TV show details asynchronously
    @MainActor
    public func fetchTVShowDetail() async {
        state = .loading
        do {
            let result: TVShowDetailModel = try await apiService.request(.tvShowDetail(show: tvShowId))
            state = .loaded(result)
        } catch {
            state = .error(error)
        }
    }
}
