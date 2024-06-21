//
//  SwiftUIView.swift
//  
//
//  Created by Quang on 2024-06-09.
//

import SwiftUI
@available(iOS 15,*)
struct TMDBAPITabView: View {
    
    @State private var currentIndex = 0
        private let views: [AnyView] = [
            AnyView(DMSNowPlayingView()),
            AnyView(SecondView()),
            AnyView(ThirdView())
        ]
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                views[currentIndex]
                
                Spacer()
            }
            .navigationBarTitle("TMDB API Example", displayMode: .inline)
            .navigationBarItems(trailing: HStack {
                previousButton
                nextButton
            })
        }
    }

    private var previousButton: some View {
        Button(action: previousView) {
            Text("<")
        }
        .disabled(currentIndex == 0)
    }

    private var nextButton: some View {
        Button(action: nextView) {
            Text(">")
        }
        .disabled(currentIndex == views.count - 1)
    }

    private func nextView() {
        if currentIndex < views.count - 1 {
            currentIndex += 1
        }
    }

    private func previousView() {
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }
}

struct SecondView: View {
    var body: some View {
        Text("Second View")
            .font(.largeTitle)
    }
}

struct ThirdView: View {
    var body: some View {
        Text("Third View")
            .font(.largeTitle)
    }
}
@available(iOS 15,*)
#Preview {
    TMDBAPITabView()
}
