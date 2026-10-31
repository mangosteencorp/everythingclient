//
//  TMDBTabsDemoApp.swift
//  TMDBTabsDemo
//
//  Created by Quinn Haus on 2026-10-16.
//

import SwiftUI
import TMDB
@main
struct TMDBTabsDemoApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ForEach(TMDBPreviewCatalog.allCases) { t in
                    NavigationLink(t.rawValue) {
                        t.view
                    }
                }
            }
        }
    }
}
