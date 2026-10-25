//
//  TVDetailDemoApp.swift
//  TVDetailDemo
//
//  Created by Quinn Haus on 2026-10-21.
//

import SwiftUI
import TMDB_TVShowDetail
@main
struct TVDetailDemoApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ForEach(TMDBTVShowDetailPreviewCatalog.allCases) { p in
                    NavigationLink(p.rawValue) {
                        p.view
                    }
                }
            }
        }
    }
}
