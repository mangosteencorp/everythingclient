//
//  SwiftUIView.swift
//  
//
//  Created by Quang on 2024-06-09.
//

import SwiftUI

struct TMDBAPITabView: View {
    @State private var selectionTab: Int = 0
    var body: some View {
        TabView(selection: $selectionTab,
                content:  {
            DMSNowPlayingView().tabItem { /*@START_MENU_TOKEN@*/Text("Tab Label 1")/*@END_MENU_TOKEN@*/ }.tag(1)
            Text("Tab Content 2").tabItem { /*@START_MENU_TOKEN@*/Text("Tab Label 2")/*@END_MENU_TOKEN@*/ }.tag(2)
        })
        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
}

#Preview {
    TMDBAPITabView()
}
