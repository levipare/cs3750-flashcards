//
//  RootTabView.swift
//  FlashcardAI
//
//  Created by River Bumpas on 10/15/25.
//
import SwiftUI

struct RootTabView: View {
    enum Tab { case home, camera }
    @State private var selection: Tab = .home
    var body: some View {
        TabView(selection: $selection) {
            SplashView(openCamera: { selection = .camera })
                .tabItem { Label("Home", systemImage: "house") }
                .tag(Tab.home)

            UploadImagesView()
                .tabItem { Label("Camera", systemImage: "camera") }
                .tag(Tab.camera)
        }
    }
}
