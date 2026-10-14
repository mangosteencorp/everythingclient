//
//  TMDBFeedDemoApp.swift
//  TMDBFeedDemo
//
//  Created by Quinn Haus on 2026-10-13.
//

import SwiftUI
import TMDB_Feed
@main
struct TMDBFeedDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ForEach(TMDBFeedPreviewCatalog.allCases) { p in
                NavigationLink(p.rawValue) {
                    p.view
                }
            }
        }
    }
}
