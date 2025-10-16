//
//  RootTabView.swift
//  FlashcardAI
//
//  Created by River Bumpas on 10/15/25.
//
import SwiftUI

struct RootTabView: View {
    enum Tab { case home, decks, scan, settings }
    @State private var selection: Tab = .home

    var body: some View {
        TabView(selection: $selection) {
            SplashView(openCamera: { selection = .scan })
                .tabItem { Label("Home", systemImage: "house") }
                .tag(Tab.home)
            DecksView()
                .tabItem { Label("Decks", systemImage: "square.stack.3d.up") }
                .tag(Tab.decks)
            UploadImagesView()
                .tabItem { Label("Scan", systemImage: "camera") }
                .tag(Tab.scan)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
